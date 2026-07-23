import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:reading_engine/reading_engine.dart';
import 'package:xml/xml.dart';
import 'package:mindflow/core/errors/failures.dart';
import 'package:mindflow/features/document_import/data/parsers/document_parser.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';

/// A .docx is a zip archive containing `word/document.xml`
/// (WordprocessingML). Parsed directly with `archive` + `xml` -- both
/// pure Dart, avoiding a native-plugin dependency that would need
/// reimplementing per target platform.
class DocxParser implements DocumentParser {
  static const _wNs = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

  @override
  Set<String> get supportedExtensions => {'docx'};

  @override
  Future<ReadingDocument> parse({required List<int> bytes, required String fileName}) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw ParseFailure('Could not open DOCX (invalid zip): $e');
    }

    final entry = archive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => throw const ParseFailure('Malformed DOCX: word/document.xml not found'),
    );

    final xmlDoc = XmlDocument.parse(utf8.decode(entry.content as List<int>, allowMalformed: true));
    final blocks = <TextBlock>[];

    for (final p in xmlDoc.findAllElements('p', namespace: _wNs)) {
      final text = _paragraphText(p);
      if (text.trim().isEmpty) continue;
      blocks.add(TextBlock(
        type: _isHeading(p) ? BlockType.heading : BlockType.paragraph,
        text: text.trim(),
      ));
    }

    if (blocks.isEmpty) throw const EmptyDocumentFailure();

    return ReadingDocument(
      id: newDocumentId(fileName),
      title: titleFromFileName(fileName),
      sourceType: DocumentSourceType.docx,
      blocks: blocks,
      importedAt: DateTime.now(),
    );
  }

  String _paragraphText(XmlElement paragraph) {
    final buffer = StringBuffer();
    for (final node in paragraph.descendantElements) {
      if (node.name.local == 't') {
        buffer.write(node.innerText);
      } else if (node.name.local == 'tab' || node.name.local == 'br') {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  bool _isHeading(XmlElement paragraph) {
    final pStyle = paragraph
        .findElements('pPr', namespace: _wNs)
        .expand((pPr) => pPr.findElements('pStyle', namespace: _wNs));
    if (pStyle.isEmpty) return false;
    final styleVal = pStyle.first.getAttribute('val', namespace: _wNs);
    return styleVal != null && styleVal.toLowerCase().contains('heading');
  }
}
