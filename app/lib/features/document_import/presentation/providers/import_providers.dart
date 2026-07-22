import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/features/document_import/data/parsers/parser_registry.dart';
import 'package:mindflow/features/document_import/data/repositories/document_repository_impl.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';
import 'package:mindflow/features/document_import/domain/repositories/document_repository.dart';
import 'package:mindflow/features/document_import/domain/usecases/import_document.dart';

final parserRegistryProvider = Provider<ParserRegistry>((ref) => ParserRegistry());

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(parserRegistry: ref.watch(parserRegistryProvider));
});

final importDocumentUseCaseProvider = Provider<ImportDocument>((ref) {
  return ImportDocument(ref.watch(documentRepositoryProvider));
});

/// Drives "pick a file -> parse -> save" from the Library screen.
/// `AsyncValue` gives loading/error UI states for free.
class ImportController extends StateNotifier<AsyncValue<ReadingDocument?>> {
  final ImportDocument _importDocument;
  final ParserRegistry _registry;

  ImportController(this._importDocument, this._registry) : super(const AsyncValue.data(null));

  Future<void> pickAndImport() async {
    state = const AsyncValue.loading();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _registry.allSupportedExtensions.toList(),
        withData: true, // ensures bytes are populated on every platform
      );

      if (result == null || result.files.isEmpty) {
        state = const AsyncValue.data(null);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        state = AsyncValue.error('Could not read file bytes for "${file.name}".', StackTrace.current);
        return;
      }

      final document = await _importDocument(bytes: bytes, fileName: file.name);
      state = AsyncValue.data(document);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final importControllerProvider =
    StateNotifierProvider<ImportController, AsyncValue<ReadingDocument?>>((ref) {
  return ImportController(ref.watch(importDocumentUseCaseProvider), ref.watch(parserRegistryProvider));
});
