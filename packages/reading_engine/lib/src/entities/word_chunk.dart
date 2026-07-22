import 'block_type.dart';

/// One "flash" the RSVP display shows.
///
/// Chunks never span two [TextBlock]s -- a heading's pacing pause and an
/// image's fixed display duration only make sense if a chunk belongs to
/// exactly one block. See `Chunker` for how this boundary is enforced.
class WordChunk {
  final List<String> words;
  final BlockType blockType;
  final String? imageRef;

  const WordChunk({
    required this.words,
    required this.blockType,
    this.imageRef,
  });

  bool get isImage => blockType == BlockType.image;

  String get displayText => words.join(' ');

  int get longestWordLength =>
      words.fold(0, (max, w) => w.length > max ? w.length : max);
}
