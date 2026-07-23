import 'block_type.dart';

/// One "flash" the RSVP display shows.
///
/// Chunks never span two [TextBlock]s -- a heading's pacing pause and an
/// image's fixed display duration only make sense if a chunk belongs to
/// exactly one block, and so does "quote the paragraph I'm reading"
/// (see `RsvpController.currentBlockText` on the app side). [blockIndex]
/// is what makes two consecutive but distinct paragraphs (which usually
/// share the same [blockType]) distinguishable -- see `Chunker`.
class WordChunk {
  final List<String> words;
  final BlockType blockType;
  final int blockIndex;
  final String? imageRef;

  const WordChunk({
    required this.words,
    required this.blockType,
    required this.blockIndex,
    this.imageRef,
  });

  bool get isImage => blockType == BlockType.image;

  String get displayText => words.join(' ');

  int get longestWordLength =>
      words.fold(0, (max, w) => w.length > max ? w.length : max);
}
