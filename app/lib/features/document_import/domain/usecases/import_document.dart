import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';
import 'package:mindflow/features/document_import/domain/repositories/document_repository.dart';

/// Import + persist as one business rule, kept out of the UI layer so
/// it's independently testable.
class ImportDocument {
  final DocumentRepository repository;
  ImportDocument(this.repository);

  Future<ReadingDocument> call({required List<int> bytes, required String fileName}) async {
    final document = await repository.importFromFile(bytes: bytes, fileName: fileName);
    await repository.saveToLibrary(document);
    return document;
  }
}
