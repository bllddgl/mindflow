import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/core/storage/app_database.dart';
import 'package:mindflow/features/quotes/domain/quote.dart';

/// Saved "favorite sentence" snippets. Kept as a simple direct-to-sqflite
/// repository -- like bookmarks, there's no alternate implementation on
/// the roadmap that would justify a full domain interface layer.
class QuoteRepository {
  Future<List<Quote>> all() async {
    final db = await AppDatabase.instance();
    final rows = await db.query('quotes', orderBy: 'created_at DESC');
    return rows
        .map((r) => Quote(
              id: r['id'] as int,
              documentId: r['document_id'] as String,
              documentTitle: r['document_title'] as String,
              text: r['text'] as String,
              createdAt: DateTime.parse(r['created_at'] as String),
            ))
        .toList();
  }

  Future<void> add({required String documentId, required String documentTitle, required String text}) async {
    if (text.trim().isEmpty) return;
    final db = await AppDatabase.instance();
    await db.insert('quotes', {
      'document_id': documentId,
      'document_title': documentTitle,
      'text': text.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> remove(int id) async {
    final db = await AppDatabase.instance();
    await db.delete('quotes', where: 'id = ?', whereArgs: [id]);
  }
}

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) => QuoteRepository());

final quotesProvider = FutureProvider<List<Quote>>((ref) {
  return ref.watch(quoteRepositoryProvider).all();
});
