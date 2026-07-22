import 'block_type.dart';

/// One block of source content, in reading order.
///
/// This is the unit every document parser (TXT/PDF/DOCX/Markdown/HTML)
/// normalises down to. For [BlockType.image], [text] is empty and
/// [imageRef] carries a reference (e.g. a data URI or asset path) the
/// presentation layer can render.
class TextBlock {
  final BlockType type;
  final String text;
  final String? imageRef;

  const TextBlock({
    required this.type,
    this.text = '',
    this.imageRef,
  });

  bool get isImage => type == BlockType.image;
}
