/// Playback tuning parameters. Pure data, no persistence knowledge --
/// the app layer is responsible for loading/saving these (Hive, in
/// MindFlow's case) and constructing this object.
class ReaderSettings {
  final int wpm;
  final int wordsPerGroup;
  final int lineCount;
  final int imageDisplayMs;

  const ReaderSettings({
    required this.wpm,
    required this.wordsPerGroup,
    required this.lineCount,
    this.imageDisplayMs = 2000,
  });

  ReaderSettings copyWith({
    int? wpm,
    int? wordsPerGroup,
    int? lineCount,
    int? imageDisplayMs,
  }) {
    return ReaderSettings(
      wpm: wpm ?? this.wpm,
      wordsPerGroup: wordsPerGroup ?? this.wordsPerGroup,
      lineCount: lineCount ?? this.lineCount,
      imageDisplayMs: imageDisplayMs ?? this.imageDisplayMs,
    );
  }
}
