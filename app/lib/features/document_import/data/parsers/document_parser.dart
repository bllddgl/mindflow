import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';

/// Contract every file-format importer implements -- the extensibility
/// seam for the whole app. Adding EPUB later: implement `EpubParser`,
/// register it in [ParserRegistry], nothing else changes. OCR follows
/// the same shape: it takes image bytes, runs recognition internally,
/// and still returns a normal [ReadingDocument].
abstract class DocumentParser {
  /// Lowercase extensions this parser handles, without the dot.
  Set<String> get supportedExtensions;

  Future<ReadingDocument> parse({required List<int> bytes, required String fileName});
}

String titleFromFileName(String fileName) =>
    fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

String newDocumentId(String fileName) =>
    '${DateTime.now().microsecondsSinceEpoch}-$fileName';
