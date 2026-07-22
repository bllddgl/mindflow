import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';
import 'package:mindflow/features/document_import/presentation/providers/import_providers.dart';

final libraryProvider = FutureProvider<List<ReadingDocument>>((ref) async {
  return ref.watch(documentRepositoryProvider).loadLibrary();
});

final removeFromLibraryProvider = Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return (String id) async {
    await repository.removeFromLibrary(id);
    ref.invalidate(libraryProvider);
  };
});

final reorderLibraryProvider = Provider<Future<void> Function(List<String>)>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return (List<String> orderedIds) async {
    await repository.reorderLibrary(orderedIds);
    ref.invalidate(libraryProvider);
  };
});
