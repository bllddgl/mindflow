import 'package:reading_engine/reading_engine.dart';

enum DocumentSourceType { txt, pdf, docx, markdown, html }

/// The normalised, format-agnostic representation every parser produces.
/// `blocks` reuses [TextBlock] from the `reading_engine` package directly
/// -- one shared vocabulary between "what a parser extracts" and "what the
/// RSVP engine tokenizes", instead of two parallel models that need
/// mapping back and forth.
class ReadingDocument {
  final String id;
  final String title;
  final DocumentSourceType sourceType;
  final List<TextBlock> blocks;
  final DateTime importedAt;
  final int sortOrder;

  /// Path to a saved copy of the original file, if one was kept (only
  /// done for PDFs today) -- lets the reader offer a "view original
  /// pages" mode showing the document exactly as designed, alongside
  /// the RSVP/reflowed-text experience which is this app's main point.
  final String? originalFilePath;

  const ReadingDocument({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.blocks,
    required this.importedAt,
    this.sortOrder = 0,
    this.originalFilePath,
  });

  int get wordCount => blocks
      .where((b) => !b.isImage)
      .fold(0, (sum, b) => sum + b.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length);
}
