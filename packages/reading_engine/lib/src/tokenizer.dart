import 'entities/block_type.dart';
import 'entities/text_block.dart';

/// A single word, still tagged with which block it came from.
/// Internal to the engine -- [Chunker] consumes this, nothing outside
/// the package needs to see it.
class Token {
  final String word;
  final BlockType blockType;
  final String? imageRef;

  const Token(this.word, this.blockType, {this.imageRef});
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
    for (final block in blocks) {
      if (block.isImage) {
        tokens.add(Token('', block.type, imageRef: block.imageRef));
        continue;
      }
      final cleaned = block.text.replaceAllMapped(
        _spaceBeforePunctuation,
        (m) => m.group(1)!,
      );
      final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
      for (final w in words) {
        tokens.add(Token(w, block.type));
      }
    }
    return tokens;
  }
}
