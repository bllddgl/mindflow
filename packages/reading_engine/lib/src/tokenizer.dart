import 'entities/block_type.dart';
import 'entities/text_block.dart';

/// A single word, tagged with which block it came from.
///
/// [blockIndex] identifies the exact source [TextBlock] (its position in
/// the original list), not just its [blockType]. This distinction
/// matters: two consecutive plain paragraphs share the same `blockType`
/// (`paragraph`) but are still two separate blocks -- without
/// [blockIndex], nothing downstream (chunking, "quote this paragraph")
/// could tell where one paragraph ends and the next begins whenever
/// they're the same type, which is the common case for most documents.
class Token {
  final String word;
  final BlockType blockType;
  final int blockIndex;
  final String? imageRef;

  const Token(this.word, this.blockType, this.blockIndex, {this.imageRef});
}

/// Splits [TextBlock]s into a flat, block-aware token stream.
///
/// Kept separate from [Chunker] for the same reason as in the original
/// design: tokenizing is a one-time cost per document, chunking (grouping
/// by `wordsPerGroup`) happens every time that setting changes.
class Tokenizer {
  /// Punctuation that should always cling to the word before it, never
  /// start a new flash on its own. PDF text extraction in particular
  /// sometimes emits a spurious space before punctuation (a glyph-spacing
  /// artifact of the source PDF) -- e.g. "word ." instead of "word." --
  /// which would otherwise show the period as if it belonged to the next
  /// word in RSVP mode. This normalises that away for every format, since
  /// all parsers funnel through this one tokenizer.
  static final _spaceBeforePunctuation = RegExp(r'\s+([.,!?;:%\)\]\}»”’])');

  List<Token> tokenize(List<TextBlock> blocks) {
    final tokens = <Token>[];
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.isImage) {
        tokens.add(Token('', block.type, i, imageRef: block.imageRef));
        continue;
      }
      final cleaned = block.text.replaceAllMapped(
        _spaceBeforePunctuation,
        (m) => m.group(1)!,
      );
      final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
      for (final w in words) {
        tokens.add(Token(w, block.type, i));
      }
    }
    return tokens;
  }
}
