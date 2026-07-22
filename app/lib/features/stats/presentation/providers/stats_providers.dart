import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/core/storage/app_database.dart';

class ReadingStats {
  final int totalWordsRead;
  final int totalSessions;
  final int totalMinutesRead;

  const ReadingStats({
    this.totalWordsRead = 0,
    this.totalSessions = 0,
    this.totalMinutesRead = 0,
  });
}

/// Records one reading session (called when the reader screen is left)
/// and reads back simple aggregates. A dedicated daily-aggregate table
/// (as sketched in the original design doc) is deferred until there's
/// enough history data to make querying `reading_history` directly slow.
class StatsRepository {
  Future<void> recordSession({
    required String documentId,
    required int wordsRead,
    required int durationMs,
  }) async {
    if (wordsRead <= 0) return;
    final db = await AppDatabase.instance();
    await db.insert('reading_history', {
      'document_id': documentId,
      'opened_at': DateTime.now().toIso8601String(),
      'words_read': wordsRead,
      'duration_ms': durationMs,
    });
  }

  Future<ReadingStats> summary() async {
    final db = await AppDatabase.instance();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as sessions, COALESCE(SUM(words_read), 0) as words, '
      'COALESCE(SUM(duration_ms), 0) as duration_ms FROM reading_history',
    );
    final row = rows.first;
    return ReadingStats(
      totalSessions: row['sessions'] as int,
      totalWordsRead: row['words'] as int,
      totalMinutesRead: ((row['duration_ms'] as int) / 60000).round(),
    );
  }
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) => StatsRepository());

final statsSummaryProvider = FutureProvider<ReadingStats>((ref) {
  return ref.watch(statsRepositoryProvider).summary();
});
