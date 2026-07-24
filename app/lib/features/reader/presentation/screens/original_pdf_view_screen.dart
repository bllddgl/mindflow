import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Renders the actual PDF pages exactly as designed -- real page images,
/// pinch-to-zoom, page-by-page navigation -- using Syncfusion's PDF
/// Viewer widget. This is deliberately a separate mode from the RSVP
/// reader (this app's main point) and from `_FullTextSheet`'s reflowed
/// text view: some readers want to double-check something against the
/// document's real layout (a table, a diagram, exact page numbers),
/// which no text-extraction-based view can ever fully replace.
///
/// Only available for PDFs -- there's no equivalent "render exactly as
/// authored" widget for DOCX/HTML/Markdown/TXT in Flutter today.
class OriginalPdfViewScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const OriginalPdfViewScreen({super.key, required this.filePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SfPdfViewer.file(File(filePath)),
    );
  }
}
