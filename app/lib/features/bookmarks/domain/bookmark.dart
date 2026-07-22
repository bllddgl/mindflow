class Bookmark {
  final int? id;
  final String documentId;
  final int chunkIndex;
  final String? note;
  final DateTime createdAt;

  const Bookmark({
    this.id,
    required this.documentId,
    required this.chunkIndex,
    this.note,
    required this.createdAt,
  });
}
