import 'package:mindflow/core/errors/failures.dart';
import 'package:mindflow/features/document_import/data/parsers/docx_parser.dart';
import 'package:mindflow/features/document_import/data/parsers/document_parser.dart';
import 'package:mindflow/features/document_import/data/parsers/html_parser.dart';
import 'package:mindflow/features/document_import/data/parsers/markdown_parser.dart';
import 'package:mindflow/features/document_import/data/parsers/pdf_parser.dart';
import 'package:mindflow/features/document_import/data/parsers/txt_parser.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';

/// Central lookup from file extension to [DocumentParser]. Adding EPUB or
/// OCR later is exactly one call to [register] -- nothing else changes.
class ParserRegistry {
  final List<DocumentParser> _parsers;

  ParserRegistry({List<DocumentParser>? parsers})
      : _parsers = parsers ??
            [
              TxtParser(),
              PdfParser(),
              DocxParser(),
              MarkdownParser(),
              HtmlParser(),
            ];

  void register(DocumentParser parser) => _parsers.add(parser);

  Set<String> get allSupportedExtensions =>
      _parsers.expand((p) => p.supportedExtensions).toSet();

  Future<ReadingDocument> parse({required List<int> bytes, required String fileName}) async {
    final extension = _extensionOf(fileName);
    final parser = _parsers.firstWhere(
      (p) => p.supportedExtensions.contains(extension),
      orElse: () => throw UnsupportedFileTypeFailure(extension),
    );
    return parser.parse(bytes: bytes, fileName: fileName);
  }

  String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }
}
