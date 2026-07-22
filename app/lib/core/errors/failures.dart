/// Lightweight, dependency-free failure types shared across features.
/// The `data` layer throws/catches real exceptions; `domain` and above
/// deal in these typed [Failure]s so the UI can branch on them without
/// knowing about file I/O or parsing-library internals.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class UnsupportedFileTypeFailure extends Failure {
  const UnsupportedFileTypeFailure(String extension)
      : super('Unsupported file type: "$extension".');
}

class FileReadFailure extends Failure {
  const FileReadFailure(super.message);
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

class EmptyDocumentFailure extends Failure {
  const EmptyDocumentFailure() : super('The document contains no readable text.');
}
