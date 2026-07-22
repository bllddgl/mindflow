import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindflow/core/l10n/app_strings.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';
import 'package:mindflow/features/document_import/presentation/providers/import_providers.dart';
import 'package:mindflow/features/library/presentation/providers/library_providers.dart';
import 'package:mindflow/features/settings/presentation/providers/app_settings_provider.dart';

/// Home screen: shows previously imported documents. Uses a single,
/// drag-to-reorder list rather than a responsive multi-column grid --
/// deliberately, since manual ordering (the whole point of this screen
/// now) doesn't translate cleanly to a grid, and phones are still this
/// app's primary target platform.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appSettingsProvider).language;
    final libraryAsync = ref.watch(libraryProvider);
    final importState = ref.watch(importControllerProvider);

    ref.listen(importControllerProvider, (previous, next) {
      next.whenData((document) {
        if (document != null) {
          ref.invalidate(libraryProvider);
          ref.read(importControllerProvider.notifier).reset();
          if (context.mounted) context.push('/reader', extra: document);
        }
      });
      if (next.hasError && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.t(lang, 'importFailed')}: ${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(lang, 'libraryTitle'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: importState.isLoading
            ? null
            : () => ref.read(importControllerProvider.notifier).pickAndImport(),
        icon: importState.isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add),
        label: Text(AppStrings.t(lang, 'libraryImportButton')),
      ),
      body: libraryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('$e')),
        data: (documents) {
          if (documents.isEmpty) {
            return _EmptyLibrary(lang: lang);
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: documents.length,
            onReorder: (oldIndex, newIndex) {
              final reordered = [...documents];
              if (newIndex > oldIndex) newIndex -= 1;
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              ref.read(reorderLibraryProvider)(reordered.map((d) => d.id).toList());
            },
            itemBuilder: (context, index) {
              final doc = documents[index];
              return _LibraryTile(key: ValueKey(doc.id), document: doc, position: index + 1, lang: lang);
            },
          );
        },
      ),
    );
  }
}

class _LibraryTile extends ConsumerWidget {
  final ReadingDocument document;
  final int position;
  final dynamic lang;
  const _LibraryTile({super.key, required this.document, required this.position, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('$position')),
        title: Text(document.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${document.wordCount} ${AppStrings.t(lang, 'libraryWords')}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: AppStrings.t(lang, 'details'),
              onPressed: () => _showDetails(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: AppStrings.t(lang, 'delete'),
              onPressed: () async {
                await ref.read(removeFromLibraryProvider)(document.id);
              },
            ),
            const SizedBox(width: 4),
            const Icon(Icons.drag_handle),
          ],
        ),
        onTap: () => context.push('/reader', extra: document),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.t(lang, 'fileDetailsTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(document.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _DetailRow(label: AppStrings.t(lang, 'sourceTypeLabel'), value: document.sourceType.name.toUpperCase()),
            _DetailRow(label: AppStrings.t(lang, 'libraryWords'), value: '${document.wordCount}'),
            _DetailRow(label: AppStrings.t(lang, 'importedOn'), value: _formatDate(document.importedAt)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppStrings.t(lang, 'close'))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final dynamic lang;
  const _EmptyLibrary({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(AppStrings.t(lang, 'libraryEmptyTitle'),
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(AppStrings.t(lang, 'libraryEmptyBody'),
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
