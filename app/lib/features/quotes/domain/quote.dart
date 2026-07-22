class Quote {
  final int? id;
  final String documentId;
  final String documentTitle;
  final String text;
  final DateTime createdAt;

  const Quote({
    this.id,
    required this.documentId,
    required this.documentTitle,
    required this.text,
    required this.createdAt,
  });
}
