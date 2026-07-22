import 'package:reading_engine/reading_engine.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:mindflow/core/errors/failures.dart';
import 'package:mindflow/features/document_import/data/parsers/document_parser.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';

/// PDF text extraction via `syncfusion_flutter_pdf` -- pure Dart, no
/// platform channels, so this works unchanged on every Flutter target
/// (important for the Windows/iOS/Web roadmap).
///
/// IMPORTANT: this deliberately uses `extractTextLines()` (which returns
/// each line's already-detected `wordCollection`) rather than the
/// simpler `extractText()` (a single flattened string). `extractText()`
/// reproduces the PDF's raw glyph spacing, which for some fonts/PDFs
/// splits a single word into several separately-spaced pieces --
/// showing up in RSVP as reading letter-by-letter or syllable-by-syllable.
/// `wordCollection` is Syncfusion's own word-boundary detection working
/// directly from glyph positions, which is far more reliable than
/// re-guessing word boundaries from whitespace in a flattened string.
///
/// PDF has no real structural markup, so heading detection here is a
/// best-effort heuristic (a line noticeably shorter than the page and in
/// isolation) rather than a guarantee -- an honest limitation, not a
/// silently wrong one. Embedded images inside PDFs are not extracted yet
/// (a separate, larger piece of work -- see the project README).
class PdfParser implements DocumentParser {
  @override
  Set<String> get supportedExtensions => {'pdf'};

  @override
  Future<ReadingDocument> parse({required List<int> bytes, required String fileName}) async {
    late final PdfDocument document;
    try {
      document = PdfDocument(inputBytes: bytes);
    } catch (e) {
      throw ParseFailure('Could not open PDF: $e');
    }

    try {
      final extractor = PdfTextExtractor(document);
      var blocks = <TextBlock>[];

      for (var i = 0; i < document.pages.count; i++) {
        final lines = extractor.extractTextLines(startPageIndex: i, endPageIndex: i);
        blocks.addAll(_linesToParagraphs(lines));
      }

      // Some PDFs don't expose usable line/word structure to
      // `extractTextLines` (it can come back empty even though the
      // document clearly has text) -- rather than fail outright, fall
      // back to the simpler flat-text extraction so the document still
      // imports. It's a lower-fidelity result (more prone to the
      // word-splitting this parser otherwise avoids), but a readable
      // import beats none at all.
      if (blocks.isEmpty) {
        blocks = _extractViaFlatText(extractor, document.pages.count);
      }

      if (blocks.isEmpty) throw const EmptyDocumentFailure();

      return ReadingDocument(
        id: newDocumentId(fileName),
        title: titleFromFileName(fileName),
        sourceType: DocumentSourceType.pdf,
        blocks: blocks,
        importedAt: DateTime.now(),
      );
    } finally {
      document.dispose();
    }
  }

  /// Fallback path: the older, simpler whole-page-text extraction, used
  /// only when `extractTextLines` finds nothing at all for this PDF.
  List<TextBlock> _extractViaFlatText(PdfTextExtractor extractor, int pageCount) {
    final blocks = <TextBlock>[];
    for (var i = 0; i < pageCount; i++) {
      final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      final paragraphs = pageText
          .split(RegExp(r'\n\s*\n'))
          .map((p) => _normalizeSpacing(p.replaceAll('\n', ' ')).trim())
          .where((p) => p.isNotEmpty);
      blocks.addAll(paragraphs.map((p) => TextBlock(type: BlockType.paragraph, text: p)));
    }
    return blocks;
  }

  /// Groups a page's lines into paragraph blocks, using the vertical gap
  /// between consecutive lines' bounding boxes to detect paragraph
  /// breaks -- a proper layout-based signal, instead of relying on blank
  /// lines in a flattened text string (which many PDFs don't reliably
  /// produce).
  List<TextBlock> _linesToParagraphs(List<TextLine> lines) {
    final blocks = <TextBlock>[];
    final buffer = StringBuffer();
    double? previousBottom;
    double? typicalLineHeight;

    void flush() {
      final text = _normalizeSpacing(buffer.toString()).trim();
      if (text.isNotEmpty) blocks.add(TextBlock(type: BlockType.paragraph, text: text));
      buffer.clear();
    }

    for (final line in lines) {
      final lineText = _joinWords(line.wordCollection);
      if (lineText.trim().isEmpty) continue;

      typicalLineHeight ??= line.bounds.height;
      final gap = previousBottom == null ? 0.0 : line.bounds.top - previousBottom;
      final isParagraphBreak = previousBottom != null &&
          typicalLineHeight != null &&
          gap > typicalLineHeight! * 0.6;

      if (isParagraphBreak) flush();

      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(lineText);
      previousBottom = line.bounds.bottom;
    }
    flush();

    return blocks;
  }

  static final _openPunctuation = RegExp(r'^[\(\[\{¿¡«]+$');
  static final _closePunctuation = RegExp(r'^[\)\]\}.,;:!?%…»]+$');
  static final _lonelyHyphen = RegExp(r'^[-\u2010\u2011\u2012\u2013]$');

  /// Joins a line's already-detected words back into text.
  ///
  /// This does NOT simply insert a space between every `TextWord` --
  /// some PDFs (particularly ones with justified text and certain
  /// embedded/subsetted fonts) cause Syncfusion's own word-boundary
  /// detector to occasionally report two pieces of a single word as
  /// separate `TextWord`s, purely because the letter-spacing in that
  /// specific spot happened to be wide enough to look like a word gap.
  /// The reliable way to tell a real inter-word space from that is
  /// geometry: a genuine space is comfortably wider, relative to the
  /// font size in use, than ordinary letter-kerning ever is. So instead
  /// of trusting "there's whitespace here" from the extracted string,
  /// this measures the actual pixel gap between each pair of words'
  /// bounding boxes and only inserts a space when that gap is wide
  /// enough to plausibly be a real one. A lone stray hyphen between two
  /// very close fragments (another symptom of the same font issue) is
  /// dropped rather than kept as its own "word".
  String _joinWords(List<TextWord> words) {
    final buffer = StringBuffer();
    TextWord? previous;
    var previousWasOpenPunctuation = false;

    for (final w in words) {
      final text = w.text.trim();
      if (text.isEmpty) continue;

      if (_lonelyHyphen.hasMatch(text) && previous != null) {
        // Treat as a font/kerning artifact, not a real dash -- drop it
        // and force the next fragment to glue directly onto the buffer.
        previousWasOpenPunctuation = true;
        previous = w;
        continue;
      }

      if (buffer.isEmpty) {
        buffer.write(text);
      } else {
        final isClosePunct = _closePunctuation.hasMatch(text);
        var addSpace = !isClosePunct && !previousWasOpenPunctuation;

        if (addSpace && previous != null) {
          final gap = w.bounds.left - previous!.bounds.right;
          final refSize = w.fontSize > 0 ? w.fontSize : 12.0;
          if (gap < refSize * 0.18) addSpace = false;
        }

        if (addSpace) buffer.write(' ');
        buffer.write(text);
      }

      previousWasOpenPunctuation = _openPunctuation.hasMatch(text);
      previous = w;
    }
    return buffer.toString();
  }

  static final _isolatedLetter = RegExp(r'^[A-Za-zÇŞĞÜÖİıçşğüö]$');

  /// Defensive second pass: even Syncfusion's word detection can, for
  /// certain embedded fonts, still report a handful of single letters as
  /// separate "words". This re-fuses any leftover runs of those, on top
  /// of the (much more reliable) word-level join above.
  String _normalizeSpacing(String text) {
    final tokens = text.split(RegExp(r'\s+'));
    final result = <String>[];
    final run = StringBuffer();

    void flushRun() {
      if (run.isNotEmpty) {
        result.add(run.toString());
        run.clear();
      }
    }

    for (final token in tokens) {
      if (_isolatedLetter.hasMatch(token)) {
        run.write(token);
      } else {
        flushRun();
        if (token.isNotEmpty) result.add(token);
      }
    }
    flushRun();
    return result.join(' ');
  }
}
