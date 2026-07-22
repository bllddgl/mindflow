import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';

/// Domain-facing contract. Domain code knows nothing about sqflite,
/// `file_picker`, or any specific parser -- only this interface. That's
/// what lets a future platform (browser extension capturing a web page,
/// OCR from a camera) provide documents through a different
/// implementation without any domain/presentation code changing.
abstract class DocumentRepository {
  Future<ReadingDocument> importFromFile({
    required List<int> bytes,
    required String fileName,
  });

  Future<List<ReadingDocument>> loadLibrary();
  Future<void> saveToLibrary(ReadingDocument document);
  Future<void> removeFromLibrary(String documentId);

  /// Persists a new manual order for the library (drag-to-reorder),
  /// given the document IDs in their new top-to-bottom order.
  Future<void> reorderLibrary(List<String> orderedDocumentIds);
}
