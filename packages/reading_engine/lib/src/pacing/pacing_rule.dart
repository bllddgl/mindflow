import '../entities/reader_settings.dart';
import '../entities/word_chunk.dart';

/// One rule in the pacing chain-of-responsibility.
///
/// Return `null` to defer to the next rule; return a [Duration] to win.
/// This is the extensibility seam for "Smart Reading" from the product
/// spec (e.g. detecting scientific text and slowing down) -- a future
/// `TextComplexityPacingRule` plugs in here without touching anything else.
abstract class PacingRule {
  Duration? computeDuration(WordChunk chunk, ReaderSettings settings);
}
