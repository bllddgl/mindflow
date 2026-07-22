import 'dart:async';

import 'chunker.dart';
import 'entities/reader_settings.dart';
import 'entities/rsvp_engine_state.dart';
import 'entities/text_block.dart';
import 'entities/word_chunk.dart';
import 'pacing/pacing_chain.dart';
import 'tokenizer.dart';

/// The engine's playback controller. Framework-agnostic: no Flutter,
/// no Riverpod. Exposes a broadcast [Stream] of state so *any* host
/// (a Flutter `StateNotifier`, a plain CLI tool, a future JS interop
/// layer) can observe playback without this class knowing about them.
class RsvpSession {
  final _tokenizer = Tokenizer();
  final _chunker = Chunker();
  final _pacing = PacingChain();

  final _controller = StreamController<RsvpEngineState>.broadcast();
  RsvpEngineState _state = const RsvpEngineState();
  Timer? _timer;

  List<TextBlock> _blocks = [];
  ReaderSettings _settings;

  RsvpSession({required ReaderSettings initialSettings}) : _settings = initialSettings;

  Stream<RsvpEngineState> get stateStream => _controller.stream;
  RsvpEngineState get state => _state;

  void loadDocument(List<TextBlock> blocks) {
    _timer?.cancel();
    _blocks = blocks;
    final chunks = _chunker.chunk(_tokenizer.tokenize(blocks), wordsPerGroup: _settings.wordsPerGroup);
    _emit(RsvpEngineState(chunks: chunks));
  }

  /// Call whenever wpm / wordsPerGroup / lineCount change. Re-chunks
  /// (only actually needed when wordsPerGroup changed) while preserving
  /// the reader's approximate position.
  void updateSettings(ReaderSettings settings) {
    final wordsPerGroupChanged = settings.wordsPerGroup != _settings.wordsPerGroup;
    _settings = settings;
    if (wordsPerGroupChanged && _blocks.isNotEmpty) {
      final wordsReadSoFar = _approxWordsBefore(_state.currentIndex);
      final chunks = _chunker.chunk(_tokenizer.tokenize(_blocks), wordsPerGroup: settings.wordsPerGroup);
      final newIndex = _findIndexForWordCount(chunks, wordsReadSoFar);
      _emit(_state.copyWith(chunks: chunks, currentIndex: newIndex));
    }
    if (_state.isPlaying) _scheduleNext();
  }

  int _approxWordsBefore(int chunkIndex) {
    var count = 0;
    for (var i = 0; i < chunkIndex && i < _state.chunks.length; i++) {
      count += _state.chunks[i].words.length;
    }
    return count;
  }

  int _findIndexForWordCount(List<WordChunk> chunks, int wordCount) {
    var count = 0;
    for (var i = 0; i < chunks.length; i++) {
      count += chunks[i].words.length;
      if (count >= wordCount) return i;
    }
    return chunks.isEmpty ? 0 : chunks.length - 1;
  }

  void play() {
    if (_state.chunks.isEmpty || _state.isPlaying) return;
    if (_state.isFinished) {
      _emit(_state.copyWith(currentIndex: 0, isFinished: false));
    }
    _emit(_state.copyWith(isPlaying: true));
    _scheduleNext();
  }

  void pause() {
    _timer?.cancel();
    _emit(_state.copyWith(isPlaying: false));
  }

  void togglePlayPause() => _state.isPlaying ? pause() : play();

  void rewind({int steps = 1}) => _seekByChunks(-steps);

  void forward({int steps = 1}) => _seekByChunks(steps);

  void seekToFraction(double fraction) {
    if (_state.chunks.isEmpty) return;
    final index = (fraction.clamp(0.0, 1.0) * (_state.chunks.length - 1)).round();
    _emit(_state.copyWith(currentIndex: index, isFinished: false));
    if (_state.isPlaying) _scheduleNext();
  }

  /// Seeks to an exact chunk index -- used for resuming a document at the
  /// exact position it was left at, where a rounded fraction could drift.
  void seekToChunkIndex(int index) {
    if (_state.chunks.isEmpty) return;
    final clamped = index.clamp(0, _state.chunks.length - 1);
    _emit(_state.copyWith(currentIndex: clamped, isFinished: false));
    if (_state.isPlaying) _scheduleNext();
  }

  void _seekByChunks(int delta) {
    if (_state.chunks.isEmpty) return;
    final newIndex = (_state.currentIndex + delta).clamp(0, _state.chunks.length - 1);
    _emit(_state.copyWith(currentIndex: newIndex, isFinished: false));
    if (_state.isPlaying) _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    final chunk = _state.currentChunk;
    if (chunk == null) return;
    _timer = Timer(_pacing.durationFor(chunk, _settings), _advance);
  }

  void _advance() {
    final nextIndex = _state.currentIndex + 1;
    if (nextIndex >= _state.chunks.length) {
      _emit(_state.copyWith(isPlaying: false, isFinished: true));
      return;
    }
    _emit(_state.copyWith(currentIndex: nextIndex));
    _scheduleNext();
  }

  void _emit(RsvpEngineState newState) {
    _state = newState;
    _controller.add(_state);
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
