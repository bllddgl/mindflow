import '../entities/reader_settings.dart';
import '../entities/word_chunk.dart';
import 'pacing_rule.dart';

/// Images get a fixed, user-configurable display duration rather than a
/// word-count-based one -- there are no words to time against.
class ImagePacingRule implements PacingRule {
  @override
  Duration? computeDuration(WordChunk chunk, ReaderSettings settings) {
    if (!chunk.isImage) return null;
    return Duration(milliseconds: settings.imageDisplayMs);
  }
}
