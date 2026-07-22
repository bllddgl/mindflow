import '../entities/reader_settings.dart';
import '../entities/word_chunk.dart';
import 'default_pacing_rule.dart';
import 'heading_pacing_rule.dart';
import 'image_pacing_rule.dart';
import 'pacing_rule.dart';
import 'quote_pacing_rule.dart';

/// Runs each [PacingRule] in order and returns the first non-null result.
/// [DefaultPacingRule] is always last, guaranteeing a result.
class PacingChain {
  final List<PacingRule> _rules;

  PacingChain() : _rules = _buildDefaultChain();

  static List<PacingRule> _buildDefaultChain() {
    final base = DefaultPacingRule();
    return [
      ImagePacingRule(),
      HeadingPacingRule(base),
      QuotePacingRule(base),
      base,
    ];
  }

  Duration durationFor(WordChunk chunk, ReaderSettings settings) {
    for (final rule in _rules) {
      final result = rule.computeDuration(chunk, settings);
      if (result != null) return result;
    }
    // Unreachable: DefaultPacingRule always returns a value.
    return const Duration(milliseconds: 300);
  }
}
