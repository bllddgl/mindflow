import 'dart:convert';

import 'package:reading_engine/reading_engine.dart';
import 'package:mindflow/features/document_import/data/parsers/document_parser.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';

/// Plain text. Splits on blank lines to recover paragraph boundaries;
/// single newlines inside a paragraph are treated as soft wraps.
class TxtParser implements DocumentParser {
  @override
  Set<String> get supportedExtensions => {'txt'};

  @override
  Future<ReadingDocument> parse({required List<int> bytes, required String fileName}) async {
    final decoded = utf8.decode(bytes, allowMalformed: true);
    final blocks = decoded
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.replaceAll('\n', ' ').trim())
        .where((p) => p.isNotEmpty)
        .map((p) => TextBlock(type: BlockType.paragraph, text: p))
        .toList();

    return ReadingDocument(
      id: newDocumentId(fileName),
      title: titleFromFileName(fileName),
      sourceType: DocumentSourceType.txt,
      blocks: blocks,
      importedAt: DateTime.now(),
    );
  }
}
