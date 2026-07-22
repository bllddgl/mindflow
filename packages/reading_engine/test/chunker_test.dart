import 'package:reading_engine/reading_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Chunker', () {
    test('groups words into chunks of the requested size', () {
      final tokenizer = Tokenizer();
      final chunker = Chunker();
      final blocks = [
        const TextBlock(type: BlockType.paragraph, text: 'one two three four five'),
      ];
      final tokens = tokenizer.tokenize(blocks);
      final chunks = chunker.chunk(tokens, wordsPerGroup: 2);

      expect(chunks.length, 3);
      expect(chunks[0].words, ['one', 'two']);
      expect(chunks[1].words, ['three', 'four']);
      expect(chunks[2].words, ['five']);
    });

    test('never merges words across a block boundary', () {
      final tokenizer = Tokenizer();
      final chunker = Chunker();
      final blocks = [
        const TextBlock(type: BlockType.heading, text: 'Title'),
        const TextBlock(type: BlockType.paragraph, text: 'Body text here'),
      ];
      final tokens = tokenizer.tokenize(blocks);
      final chunks = chunker.chunk(tokens, wordsPerGroup: 5);

      expect(chunks.length, 2);
      expect(chunks[0].blockType, BlockType.heading);
      expect(chunks[1].blockType, BlockType.paragraph);
    });

    test('images become their own single chunk', () {
      final tokenizer = Tokenizer();
      final chunker = Chunker();
      final blocks = [
        const TextBlock(type: BlockType.paragraph, text: 'before'),
        const TextBlock(type: BlockType.image, imageRef: 'img1.png'),
        const TextBlock(type: BlockType.paragraph, text: 'after'),
      ];
      final tokens = tokenizer.tokenize(blocks);
      final chunks = chunker.chunk(tokens, wordsPerGroup: 5);

      expect(chunks.length, 3);
      expect(chunks[1].isImage, isTrue);
      expect(chunks[1].imageRef, 'img1.png');
    });
  });
}
