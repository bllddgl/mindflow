import '../entities/block_type.dart';
import '../entities/reader_settings.dart';
import '../entities/word_chunk.dart';
import 'pacing_rule.dart';
import 'default_pacing_rule.dart';

/// Headings get the normal word-timing plus a one-second pause, giving
/// the reader a moment to register a section change.
class HeadingPacingRule implements PacingRule {
  final DefaultPacingRule _base;
  HeadingPacingRule(this._base);

  @override
  Duration? computeDuration(WordChunk chunk, ReaderSettings settings) {
    if (chunk.blockType != BlockType.heading) return null;
    final base = _base.computeDuration(chunk, settings) ?? Duration.zero;
    return base + const Duration(seconds: 1);
  }
}
