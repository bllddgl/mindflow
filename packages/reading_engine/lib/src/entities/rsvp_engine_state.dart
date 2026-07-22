import 'word_chunk.dart';

/// Immutable playback snapshot emitted by [RsvpSession].
class RsvpEngineState {
  final List<WordChunk> chunks;
  final int currentIndex;
  final bool isPlaying;
  final bool isFinished;

  const RsvpEngineState({
    this.chunks = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isFinished = false,
  });

  WordChunk? get currentChunk =>
      chunks.isEmpty ? null : chunks[currentIndex.clamp(0, chunks.length - 1)];

  double get progress =>
      chunks.isEmpty ? 0 : (currentIndex + 1) / chunks.length;

  RsvpEngineState copyWith({
    List<WordChunk>? chunks,
    int? currentIndex,
    bool? isPlaying,
    bool? isFinished,
  }) {
    return RsvpEngineState(
      chunks: chunks ?? this.chunks,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}
