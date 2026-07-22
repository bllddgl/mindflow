/// Public API of the MindFlow reading engine. Import only this file from
/// the app -- everything under `src/` is implementation detail.
library reading_engine;

export 'src/chunker.dart';
export 'src/entities/block_type.dart';
export 'src/entities/reader_settings.dart';
export 'src/entities/rsvp_engine_state.dart';
export 'src/entities/text_block.dart';
export 'src/entities/word_chunk.dart';
export 'src/pacing/pacing_chain.dart';
export 'src/rsvp_session.dart';
export 'src/tokenizer.dart';
