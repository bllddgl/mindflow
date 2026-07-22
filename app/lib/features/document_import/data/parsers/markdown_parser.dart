import 'dart:convert';

import 'package:markdown/markdown.dart' as md;
import 'package:reading_engine/reading_engine.dart';
import 'package:mindflow/core/errors/failures.dart';
import 'package:mindflow/features/document_import/data/parsers/document_parser.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';

/// Parses Markdown via `package:markdown`'s AST (not regex) so nested
/// structure (lists, blockquotes, image-only lines) is handled correctly
/// rather than approximated. Code blocks and tables are intentionally
/// degraded to plain paragraphs in v1 -- honest about what's not yet
/// specially rendered, rather than mis-rendering them.
class MarkdownParser implements DocumentParser {
  @override
  Set<String> get supportedExtensions => {'md', 'markdown'};

  @override
  Future<ReadingDocument> parse({required List<int> bytes, required String fileName}) async {
    final source = utf8.decode(bytes, allowMalformed: true);
    final nodes = md.Document(extensionSet: md.ExtensionSet.gitHubWeb)
        .parseLines(source.split('\n'));

    final blocks = <TextBlock>[];
    for (final node in nodes) {
      blocks.addAll(_convert(node));
    }

    if (blocks.isEmpty) throw const EmptyDocumentFailure();

    return ReadingDocument(
      id: newDocumentId(fileName),
      title: titleFromFileName(fileName),
      sourceType: DocumentSourceType.markdown,
      blocks: blocks,
      importedAt: DateTime.now(),
    );
  }

  List<TextBlock> _convert(md.Node node) {
    if (node is! md.Element) return const [];

    switch (node.tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final text = node.textContent.trim();
        return text.isEmpty ? const [] : [TextBlock(type: BlockType.heading, text: text)];

      case 'blockquote':
        final text = node.textContent.trim();
        return text.isEmpty ? const [] : [TextBlock(type: BlockType.quote, text: text)];

      case 'ul':
      case 'ol':
        final items = <TextBlock>[];
        for (final child in node.children ?? const []) {
          if (child is md.Element && child.tag == 'li') {
            final text = child.textContent.trim();
            if (text.isNotEmpty) items.add(TextBlock(type: BlockType.listItem, text: text));
          }
        }
        return items;

      case 'p':
        final imageRef = _imageOnlySrc(node);
        if (imageRef != null) return [TextBlock(type: BlockType.image, imageRef: imageRef)];
        final text = node.textContent.trim();
        return text.isEmpty ? const [] : [TextBlock(type: BlockType.paragraph, text: text)];

      default:
        final text = node.textContent.trim();
        return text.isEmpty ? const [] : [TextBlock(type: BlockType.paragraph, text: text)];
    }
  }

  /// If a paragraph's only content is a single image (the common
  /// `![alt](src)` markdown pattern), return its `src` so it becomes a
  /// real image block instead of losing the reference in plain text.
  String? _imageOnlySrc(md.Element paragraph) {
    final children = paragraph.children;
    if (children == null || children.length != 1) return null;
    final only = children.first;
    if (only is md.Element && only.tag == 'img') {
      return only.attributes['src'];
    }
    return null;
  }
}
