import '../entities/block_type.dart';
import '../entities/reader_settings.dart';
import '../entities/word_chunk.dart';
import 'pacing_rule.dart';
import 'default_pacing_rule.dart';

/// Quotes are shown 15% slower than normal prose -- a small deliberate
/// deceleration for text that's usually meant to be savored, not skimmed.
class QuotePacingRule implements PacingRule {
  final DefaultPacingRule _base;
  QuotePacingRule(this._base);

  @override
  Duration? computeDuration(WordChunk chunk, ReaderSettings settings) {
    if (chunk.blockType != BlockType.quote) return null;
    final base = _base.computeDuration(chunk, settings) ?? Duration.zero;
    return base * 1.15;
  }
}
