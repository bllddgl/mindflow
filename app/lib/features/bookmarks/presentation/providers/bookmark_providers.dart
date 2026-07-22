import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/core/storage/app_database.dart';
import 'package:mindflow/features/bookmarks/domain/bookmark.dart';

/// Bookmarks are simple enough that this provider talks to sqflite
/// directly rather than through a full repository interface -- there's
/// no alternate implementation on the roadmap the way there is for
/// document import (parsers) or AI. Keeping the abstraction proportional
/// to the actual need, not adding a layer "just in case".
class BookmarkRepository {
  Future<List<Bookmark>> forDocument(String documentId) async {
    final db = await AppDatabase.instance();
    final rows = await db.query('bookmarks',
        where: 'document_id = ?', whereArgs: [documentId], orderBy: 'chunk_index ASC');
    return rows
        .map((r) => Bookmark(
              id: r['id'] as int,
              documentId: r['document_id'] as String,
              chunkIndex: r['chunk_index'] as int,
              note: r['note'] as String?,
              createdAt: DateTime.parse(r['created_at'] as String),
            ))
        .toList();
  }

  Future<void> add({required String documentId, required int chunkIndex}) async {
    final db = await AppDatabase.instance();
    await db.insert('bookmarks', {
      'document_id': documentId,
      'chunk_index': chunkIndex,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> remove(int bookmarkId) async {
    final db = await AppDatabase.instance();
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [bookmarkId]);
  }
}

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) => BookmarkRepository());

final bookmarksForDocumentProvider =
    FutureProvider.family<List<Bookmark>, String>((ref, documentId) {
  return ref.watch(bookmarkRepositoryProvider).forDocument(documentId);
});
