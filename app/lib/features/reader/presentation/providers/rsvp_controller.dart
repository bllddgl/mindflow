import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_engine/reading_engine.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';
import 'package:mindflow/features/settings/presentation/providers/app_settings_provider.dart';

/// Thin Flutter adapter around the pure-Dart [RsvpSession]. This class
/// owns no timing logic itself -- it only (a) constructs the engine with
/// settings converted from Hive-backed [AppSettings], (b) forwards user
/// intents (play/pause/rewind/...) to the session, and (c) mirrors the
/// session's state stream into Riverpod so widgets can `ref.watch` it.
class RsvpController extends StateNotifier<RsvpEngineState> {
  final Ref _ref;
  late final RsvpSession _session;
  StreamSubscription<RsvpEngineState>? _sub;
  String _documentTitle = '';

  RsvpController(this._ref) : super(const RsvpEngineState()) {
    _session = RsvpSession(initialSettings: _settingsToEngine(_ref.read(appSettingsProvider)));
    _sub = _session.stateStream.listen((s) => state = s);

    _ref.listen<AppSettings>(appSettingsProvider, (previous, next) {
      if (previous?.wpm != next.wpm ||
          previous?.wordsPerGroup != next.wordsPerGroup ||
          previous?.lineCount != next.lineCount ||
          previous?.imageDisplayMs != next.imageDisplayMs) {
        _session.updateSettings(_settingsToEngine(next));
      }
    });
  }

  String get documentTitle => _documentTitle;

  static ReaderSettings _settingsToEngine(AppSettings s) => ReaderSettings(
        wpm: s.wpm,
        wordsPerGroup: s.wordsPerGroup,
        lineCount: s.lineCount,
        imageDisplayMs: s.imageDisplayMs,
      );

  void loadDocument(ReadingDocument document) {
    _documentTitle = document.title;
    _session.loadDocument(document.blocks);
  }

  void play() => _session.play();
  void pause() => _session.pause();
  void togglePlayPause() => _session.togglePlayPause();
  void rewind({int steps = 1}) => _session.rewind(steps: steps);
  void forward({int steps = 1}) => _session.forward(steps: steps);
  void seekToFraction(double fraction) => _session.seekToFraction(fraction);
  void seekToChunkIndex(int index) => _session.seekToChunkIndex(index);

  /// Reconstructs the full paragraph/block the reader is currently on, by
  /// joining every consecutive chunk around the current position that
  /// shares its block type (chunks never cross a block boundary -- see
  /// `Chunker` in reading_engine -- so this naturally stops at the
  /// paragraph's edges). Used by the "save as quote" feature: quoting a
  /// single flashed word or two is rarely useful, quoting the sentence
  /// it's part of is.
  String currentBlockText() {
    final s = state;
    if (s.chunks.isEmpty) return '';
    final current = s.chunks[s.currentIndex.clamp(0, s.chunks.length - 1)];
    if (current.isImage) return '';

    var start = s.currentIndex;
    while (start > 0 && s.chunks[start - 1].blockType == current.blockType && !s.chunks[start - 1].isImage) {
      start--;
    }
    var end = s.currentIndex;
    while (end < s.chunks.length - 1 &&
        s.chunks[end + 1].blockType == current.blockType &&
        !s.chunks[end + 1].isImage) {
      end++;
    }

    return s.chunks.sublist(start, end + 1).map((c) => c.words.join(' ')).join(' ');
  }

  @override
  void dispose() {
    _sub?.cancel();
    _session.dispose();
    super.dispose();
  }
}

final rsvpControllerProvider = StateNotifierProvider<RsvpController, RsvpEngineState>((ref) {
  return RsvpController(ref);
});
