import 'entities/word_chunk.dart';
import 'tokenizer.dart';

/// Groups a token stream into [WordChunk]s of `wordsPerGroup` size.
///
/// Chunks never cross a block boundary: if a paragraph ends mid-group,
/// that group is closed early. This is what lets pacing rules reason
/// simply ("this chunk is a heading") without needing to know about
/// partial overlaps between two different block types. Image tokens
/// always become their own single-chunk group.
class Chunker {
  List<WordChunk> chunk(List<Token> tokens, {required int wordsPerGroup}) {
    final effectiveSize = wordsPerGroup < 1 ? 1 : wordsPerGroup;
    final chunks = <WordChunk>[];
    var buffer = <String>[];

    void flush(Token forBlockOf) {
      if (buffer.isEmpty) return;
      chunks.add(WordChunk(words: buffer, blockType: forBlockOf.blockType));
      buffer = [];
    }

    Token? previous;
    for (final token in tokens) {
      if (token.imageRef != null) {
        flush(previous ?? token);
        chunks.add(WordChunk(
          words: const [],
          blockType: token.blockType,
          imageRef: token.imageRef,
        ));
        previous = null;
        continue;
      }

      final blockChanged = previous != null && previous.blockType != token.blockType;
      if (blockChanged) flush(previous!);

      buffer.add(token.word);
      if (buffer.length >= effectiveSize) flush(token);
      previous = token;
    }
    if (previous != null) flush(previous);

    return chunks;
  }
}
