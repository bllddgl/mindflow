import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the single sqflite connection used for all relational data:
/// the library (documents + their blocks), bookmarks, and reading
/// history. Raw SQL, no ORM/codegen -- chosen deliberately so building
/// this project never requires a `build_runner` step.
///
/// Fast, high-frequency data (settings, "last read position") deliberately
/// does NOT live here -- see `hive_boxes.dart` for that.
class AppDatabase {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'mindflow.db');
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE documents (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            source_type TEXT NOT NULL,
            imported_at TEXT NOT NULL,
            word_count INTEGER NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE document_blocks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id TEXT NOT NULL,
            order_index INTEGER NOT NULL,
            block_type TEXT NOT NULL,
            text TEXT NOT NULL,
            image_ref TEXT,
            FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_blocks_document ON document_blocks (document_id, order_index)
        ''');
        await db.execute('''
          CREATE TABLE bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id TEXT NOT NULL,
            chunk_index INTEGER NOT NULL,
            note TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE reading_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id TEXT NOT NULL,
            opened_at TEXT NOT NULL,
            words_read INTEGER NOT NULL,
            duration_ms INTEGER NOT NULL,
            FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE quotes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id TEXT NOT NULL,
            document_title TEXT NOT NULL,
            text TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Existing installs (schema version 1) already have every table
        // except `quotes` -- add just that, so upgrading never loses the
        // library, bookmarks, or reading history already on the device.
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS quotes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              document_id TEXT NOT NULL,
              document_title TEXT NOT NULL,
              text TEXT NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE documents ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0');
          // Backfill: give existing documents a stable initial order
          // matching how they were already sorted (most recently
          // imported first), so upgrading doesn't visually shuffle an
          // existing library.
          final rows = await db.query('documents', orderBy: 'imported_at DESC');
          for (var i = 0; i < rows.length; i++) {
            await db.update('documents', {'sort_order': i}, where: 'id = ?', whereArgs: [rows[i]['id']]);
          }
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return _db!;
  }
}
