import '../entities/reader_settings.dart';
import '../entities/word_chunk.dart';
import 'pacing_rule.dart';

/// Base timing every other rule extends: (60,000ms / wpm) per word, with
/// a small allowance added for long words so they stay legible at high
/// speeds. Always returns a value -- this is the chain's fallback, never
/// deferring further.
class DefaultPacingRule implements PacingRule {
  @override
  Duration computeDuration(WordChunk chunk, ReaderSettings settings) {
    final msPerWord = 60000 / settings.wpm;
    var totalMs = msPerWord * (chunk.words.isEmpty ? 1 : chunk.words.length);
    if (chunk.longestWordLength > 7) {
      totalMs += (chunk.longestWordLength - 7) * 15;
    }
    return Duration(milliseconds: totalMs.round());
  }
}
