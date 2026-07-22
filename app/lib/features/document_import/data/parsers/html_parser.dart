import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:reading_engine/reading_engine.dart';
import 'package:mindflow/core/errors/failures.dart';
import 'package:mindflow/features/document_import/data/parsers/document_parser.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';

const _blockTags = {'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'ul', 'ol', 'blockquote', 'img'};
const _headingTags = {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'};

/// Parses HTML via `package:html`'s DOM (the same parser browsers'
/// dev tools are built on), walking `<body>` in document order so
/// reading order is preserved exactly as authored.
class HtmlParser implements DocumentParser {
  @override
  Set<String> get supportedExtensions => {'html', 'htm'};

  @override
  Future<ReadingDocument> parse({required List<int> bytes, required String fileName}) async {
    final source = utf8.decode(bytes, allowMalformed: true);
    final document = html_parser.parse(source);
    final body = document.body;
    if (body == null) throw const EmptyDocumentFailure();

    final blocks = <TextBlock>[];
    _walk(body, blocks);

    if (blocks.isEmpty) throw const EmptyDocumentFailure();

    return ReadingDocument(
      id: newDocumentId(fileName),
      title: titleFromFileName(fileName),
      sourceType: DocumentSourceType.html,
      blocks: blocks,
      importedAt: DateTime.now(),
    );
  }

  void _walk(dom.Element node, List<TextBlock> blocks) {
    for (final child in node.children) {
      if (_blockTags.contains(child.localName)) {
        blocks.addAll(_convert(child));
      } else {
        // Not a recognised block tag itself (e.g. <div>, <section>) --
        // recurse to find block tags nested inside it.
        _walk(child, blocks);
      }
    }
  }

  List<TextBlock> _convert(dom.Element el) {
    final tag = el.localName;
    if (tag != null && _headingTags.contains(tag)) {
      final text = el.text.trim();
      return text.isEmpty ? const [] : [TextBlock(type: BlockType.heading, text: text)];
    }
    switch (tag) {
      case 'blockquote':
        final text = el.text.trim();
        return text.isEmpty ? const [] : [TextBlock(type: BlockType.quote, text: text)];
      case 'ul':
      case 'ol':
        return el.children
            .where((c) => c.localName == 'li')
            .map((li) => li.text.trim())
            .where((t) => t.isNotEmpty)
            .map((t) => TextBlock(type: BlockType.listItem, text: t))
            .toList();
      case 'img':
        final src = el.attributes['src'];
        return src == null ? const [] : [TextBlock(type: BlockType.image, imageRef: src)];
      case 'p':
        final text = el.text.trim();
        return text.isEmpty ? const [] : [TextBlock(type: BlockType.paragraph, text: text)];
      default:
        return const [];
    }
  }
}
