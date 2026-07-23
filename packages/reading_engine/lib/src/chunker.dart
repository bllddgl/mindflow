import 'entities/word_chunk.dart';
import 'tokenizer.dart';

/// Groups a token stream into [WordChunk]s of `wordsPerGroup` size.
///
/// Chunks never cross a block boundary -- flushing happens whenever the
/// source block *changes*, not merely when its type changes (two
/// consecutive plain paragraphs are still two different blocks). If a
/// paragraph ends mid-group, that group is closed early rather than
/// blending words from two unrelated paragraphs into one flash. Image
/// tokens always become their own single-chunk group.
class Chunker {
  List<WordChunk> chunk(List<Token> tokens, {required int wordsPerGroup}) {
    final effectiveSize = wordsPerGroup < 1 ? 1 : wordsPerGroup;
    final chunks = <WordChunk>[];
    var buffer = <String>[];

    void flush(Token forBlockOf) {
      if (buffer.isEmpty) return;
      chunks.add(WordChunk(
        words: buffer,
        blockType: forBlockOf.blockType,
        blockIndex: forBlockOf.blockIndex,
      ));
      buffer = [];
    }

    Token? previous;
    for (final token in tokens) {
      if (token.imageRef != null) {
        flush(previous ?? token);
        chunks.add(WordChunk(
          words: const [],
          blockType: token.blockType,
          blockIndex: token.blockIndex,
          imageRef: token.imageRef,
        ));
        previous = null;
        continue;
      }

      final blockChanged = previous != null && previous.blockIndex != token.blockIndex;
      if (blockChanged) flush(previous!);

      buffer.add(token.word);
      if (buffer.length >= effectiveSize) flush(token);
      previous = token;
    }
    if (previous != null) flush(previous);

    return chunks;
  }
}
