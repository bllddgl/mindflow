import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_engine/reading_engine.dart';
import 'package:mindflow/core/constants/app_constants.dart';
import 'package:mindflow/core/l10n/app_strings.dart';
import 'package:mindflow/core/storage/hive_boxes.dart';
import 'package:mindflow/core/utils/responsive.dart';
import 'package:mindflow/features/bookmarks/presentation/providers/bookmark_providers.dart';
import 'package:mindflow/features/bookmarks/presentation/widgets/bookmarks_sheet.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';
import 'package:mindflow/features/quotes/presentation/providers/quote_providers.dart';
import 'package:mindflow/features/reader/presentation/providers/rsvp_controller.dart';
import 'package:mindflow/features/reader/presentation/widgets/progress_seek_bar.dart';
import 'package:mindflow/features/reader/presentation/widgets/reader_controls.dart';
import 'package:mindflow/features/reader/presentation/widgets/rsvp_display.dart';
import 'package:mindflow/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:mindflow/features/stats/presentation/providers/stats_providers.dart';

/// Full-screen RSVP reading experience. Outside the app's persistent nav
/// shell (see `app_router.dart`) -- readers want maximum screen space.
///
/// Deliberately minimal while reading: only the always-visible transport
/// (rewind/play-pause/forward) and progress bar are on screen. Speed /
/// words-per-group / line-count dials are one tap away behind the tune
/// icon instead of permanently on screen -- they were found to be
/// distracting to look at while actually trying to read.
class ReaderScreen extends ConsumerStatefulWidget {
  final ReadingDocument document;
  const ReaderScreen({super.key, required this.document});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _sessionStart = DateTime.now();
  static const _progressKeyPrefix = 'pos_';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(rsvpControllerProvider.notifier);
      controller.loadDocument(widget.document);

      // Auto-resume: if this document was read before, jump back to
      // exactly where the reader left off instead of starting over.
      final savedIndex = HiveBoxes.progress.get('$_progressKeyPrefix${widget.document.id}') as int?;
      if (savedIndex != null && savedIndex > 0) {
        controller.seekToChunkIndex(savedIndex);
      }
    });
  }

  @override
  void dispose() {
    final state = ref.read(rsvpControllerProvider);

    // Save exact position for next time (see initState's auto-resume).
    HiveBoxes.progress.put('$_progressKeyPrefix${widget.document.id}', state.currentIndex);

    final wordsRead = state.chunks
        .take(state.currentIndex + 1)
        .fold<int>(0, (sum, c) => sum + c.words.length);
    ref.read(statsRepositoryProvider).recordSession(
          documentId: widget.document.id,
          wordsRead: wordsRead,
          durationMs: DateTime.now().difference(_sessionStart).inMilliseconds,
        );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RsvpEngineState rsvp = ref.watch(rsvpControllerProvider);
    final settings = ref.watch(appSettingsProvider);
    final lang = settings.language;

    // Belt-and-suspenders position saving: `dispose()` also saves, but
    // its write isn't awaited (dispose can't be async) and could be lost
    // if the app process is killed very quickly after leaving this
    // screen. Checkpointing periodically while reading means there's
    // always a recent, safely-written position on disk regardless.
    ref.listen<RsvpEngineState>(rsvpControllerProvider, (previous, next) {
      if (previous?.currentIndex != next.currentIndex && next.currentIndex % 5 == 0) {
        HiveBoxes.progress.put('$_progressKeyPrefix${widget.document.id}', next.currentIndex);
      }
    });

    final fontSize = settings.fontSize.toDouble() *
        Responsive.value<double>(context, phone: 1.0, tablet: 1.2, desktop: 1.4);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_quote_outlined),
            tooltip: AppStrings.t(lang, 'quotesTitle'),
            onPressed: () async {
              ref.read(rsvpControllerProvider.notifier).pause();
              final text = ref.read(rsvpControllerProvider.notifier).currentBlockText();
              if (text.isEmpty) return;
              await ref.read(quoteRepositoryProvider).add(
                    documentId: widget.document.id,
                    documentTitle: widget.document.title,
                    text: text,
                  );
              ref.invalidate(quotesProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(AppStrings.t(lang, 'quoteSaved'))));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.article_outlined),
            tooltip: AppStrings.t(lang, 'viewOriginalText'),
            onPressed: () {
              ref.read(rsvpControllerProvider.notifier).pause();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => _FullTextSheet(document: widget.document, currentChunk: rsvp.currentChunk),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.star_border),
            tooltip: AppStrings.t(lang, 'readerBookmarks'),
            onPressed: () async {
              await ref.read(bookmarkRepositoryProvider).add(
                    documentId: widget.document.id,
                    chunkIndex: rsvp.currentIndex,
                  );
              ref.invalidate(bookmarksForDocumentProvider(widget.document.id));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.t(lang, 'readerBookmarkAdded'))),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () {
              ref.read(rsvpControllerProvider.notifier).pause();
              showModalBottomSheet(
                context: context,
                builder: (_) => BookmarksSheet(documentId: widget.document.id, totalChunks: rsvp.chunks.length),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: AppStrings.t(lang, 'readerSettings'),
            onPressed: () {
              ref.read(rsvpControllerProvider.notifier).pause();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const _ReaderSettingsSheet(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: RsvpDisplay(chunk: rsvp.currentChunk, lineCount: settings.lineCount, fontSize: fontSize),
                ),
              ),
              const ProgressSeekBar(),
              const SizedBox(height: 8),
              const ReaderControls(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Speed / words-per-group / line-count / image-duration dials, tucked
/// behind the app bar's tune icon instead of sitting permanently under
/// the RSVP display where they'd compete for attention while reading.
class _ReaderSettingsSheet extends ConsumerWidget {
  const _ReaderSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final lang = settings.language;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.t(lang, 'readerSettings'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _sheetSlider(
              context,
              label: '${AppStrings.t(lang, 'settingsFontSize')}: ${settings.fontSize}',
              value: settings.fontSize.toDouble(),
              min: AppConstants.minFontSize.toDouble(),
              max: AppConstants.maxFontSize.toDouble(),
              divisions: AppConstants.maxFontSize - AppConstants.minFontSize,
              onChanged: (v) => notifier.setFontSize(v.round()),
            ),
            _sheetSlider(
              context,
              label: '${AppStrings.t(lang, 'settingsDefaultSpeed')}: ${settings.wpm}',
              value: settings.wpm.toDouble(),
              min: AppConstants.minWpm.toDouble(),
              max: AppConstants.maxWpm.toDouble(),
              divisions: (AppConstants.maxWpm - AppConstants.minWpm) ~/ 10,
              onChanged: (v) => notifier.setWpm(v.round()),
            ),
            _sheetSlider(
              context,
              label: '${AppStrings.t(lang, 'settingsWordsAtOnce')}: ${settings.wordsPerGroup}',
              value: settings.wordsPerGroup.toDouble(),
              min: AppConstants.minWordsPerGroup.toDouble(),
              max: AppConstants.maxWordsPerGroup.toDouble(),
              divisions: AppConstants.maxWordsPerGroup - AppConstants.minWordsPerGroup,
              onChanged: (v) => notifier.setWordsPerGroup(v.round()),
            ),
            _sheetSlider(
              context,
              label: '${AppStrings.t(lang, 'settingsLineCount')}: ${settings.lineCount}',
              value: settings.lineCount.toDouble(),
              min: AppConstants.minLineCount.toDouble(),
              max: AppConstants.maxLineCount.toDouble(),
              divisions: AppConstants.maxLineCount - AppConstants.minLineCount,
              onChanged: (v) => notifier.setLineCount(v.round()),
            ),
            _sheetSlider(
              context,
              label: '${AppStrings.t(lang, 'settingsImageDuration')}: ${(settings.imageDisplayMs / 1000).toStringAsFixed(1)}s',
              value: settings.imageDisplayMs.toDouble(),
              min: AppConstants.minImageDisplayMs.toDouble(),
              max: AppConstants.maxImageDisplayMs.toDouble(),
              divisions: (AppConstants.maxImageDisplayMs - AppConstants.minImageDisplayMs) ~/ 500,
              onChanged: (v) => notifier.setImageDisplayMs(v.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Slider(value: value.clamp(min, max), min: min, max: max, divisions: divisions, onChanged: onChanged),
      ],
    );
  }
}

/// Shows the whole document as normal, continuously-scrollable text --
/// "what does this look like as a regular page" -- with the paragraph
/// the RSVP reader is currently on highlighted and scrolled into view.
/// Opened via the app bar's document icon; playback is paused first (see
/// the button's `onPressed` above) so the flashing words don't keep
/// changing underneath this view.
class _FullTextSheet extends StatefulWidget {
  final ReadingDocument document;
  final WordChunk? currentChunk;

  const _FullTextSheet({required this.document, required this.currentChunk});

  @override
  State<_FullTextSheet> createState() => _FullTextSheetState();
}

class _FullTextSheetState extends State<_FullTextSheet> {
  final _currentBlockKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _currentBlockKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, alignment: 0.3, duration: const Duration(milliseconds: 300));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentBlockIndex = widget.currentChunk?.blockIndex;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          itemCount: widget.document.blocks.length,
          itemBuilder: (context, index) {
            final block = widget.document.blocks[index];
            final isCurrent = index == currentBlockIndex;

            if (block.isImage) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Icon(Icons.image_outlined, size: 48),
              );
            }
            if (block.text.trim().isEmpty) return const SizedBox.shrink();

            return Container(
              key: isCurrent ? _currentBlockKey : null,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: isCurrent
                  ? BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Text(
                block.text,
                style: block.type == BlockType.heading
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.bodyLarge,
              ),
            );
          },
        );
      },
    );
  }
}
