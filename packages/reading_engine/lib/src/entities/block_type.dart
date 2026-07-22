/// Semantic role of a block of source text.
///
/// Kept deliberately small for v1: `table`, `footnote`, and `caption` from
/// the original product spec are intentionally *not* separate cases yet --
/// parsers fall back to `paragraph` for those (a "degraded but honest"
/// fidelity choice, see `ParseFidelity` in the app layer) rather than us
/// pretending to support rendering/pacing we haven't built yet.
enum BlockType { heading, paragraph, listItem, quote, image }
