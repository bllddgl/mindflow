import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/core/l10n/app_strings.dart';
import 'package:mindflow/features/bookmarks/presentation/providers/bookmark_providers.dart';
import 'package:mindflow/features/reader/presentation/providers/rsvp_controller.dart';
import 'package:mindflow/features/settings/presentation/providers/app_settings_provider.dart';

/// Bottom sheet listing saved bookmarks for the document currently open
/// in the reader; tapping one seeks the RSVP session to that chunk.
class BookmarksSheet extends ConsumerWidget {
  final String documentId;
  final int totalChunks;

  const BookmarksSheet({super.key, required this.documentId, required this.totalChunks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appSettingsProvider).language;
    final bookmarksAsync = ref.watch(bookmarksForDocumentProvider(documentId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.t(lang, 'readerBookmarks'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            bookmarksAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Text('$e'),
              data: (bookmarks) {
                if (bookmarks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(AppStrings.t(lang, 'readerNoBookmarks')),
                  );
                }
                return Column(
                  children: bookmarks.map((b) {
                    final pct = totalChunks == 0 ? 0 : ((b.chunkIndex / totalChunks) * 100).round();
                    return ListTile(
                      leading: const Icon(Icons.star),
                      title: Text('$pct%'),
                      onTap: () {
                        ref.read(rsvpControllerProvider.notifier).seekToFraction(
                            totalChunks == 0 ? 0 : b.chunkIndex / totalChunks);
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
