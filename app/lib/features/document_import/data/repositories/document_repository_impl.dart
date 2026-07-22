import 'package:reading_engine/reading_engine.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mindflow/core/storage/app_database.dart';
import 'package:mindflow/features/document_import/data/parsers/parser_registry.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';
import 'package:mindflow/features/document_import/domain/repositories/document_repository.dart';

/// Parses via [ParserRegistry], persists via the shared sqflite
/// connection ([AppDatabase]). `document_blocks` is a real relational
/// table (one row per block, in order) rather than one big serialised
/// blob -- this is what lets future features query "just this section"
/// or "where exactly is the image in this document" with plain SQL.
class DocumentRepositoryImpl implements DocumentRepository {
  final ParserRegistry parserRegistry;

  DocumentRepositoryImpl({required this.parserRegistry});

  @override
  Future<ReadingDocument> importFromFile({required List<int> bytes, required String fileName}) {
    return parserRegistry.parse(bytes: bytes, fileName: fileName);
  }

  @override
  Future<void> saveToLibrary(ReadingDocument document) async {
    final db = await AppDatabase.instance();
    // New documents go to the end of the manually-ordered library --
    // one past whatever the current highest sort_order is.
    final maxOrderRow = await db.rawQuery('SELECT MAX(sort_order) as maxOrder FROM documents');
    final nextOrder = ((maxOrderRow.first['maxOrder'] as int?) ?? -1) + 1;

    await db.transaction((txn) async {
      await txn.insert(
        'documents',
        {
          'id': document.id,
          'title': document.title,
          'source_type': document.sourceType.name,
          'imported_at': document.importedAt.toIso8601String(),
          'word_count': document.wordCount,
          'sort_order': nextOrder,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (var i = 0; i < document.blocks.length; i++) {
        final block = document.blocks[i];
        await txn.insert('document_blocks', {
          'document_id': document.id,
          'order_index': i,
          'block_type': block.type.name,
          'text': block.text,
          'image_ref': block.imageRef,
        });
      }
    });
  }

  @override
  Future<List<ReadingDocument>> loadLibrary() async {
    final db = await AppDatabase.instance();
    final docRows = await db.query('documents', orderBy: 'sort_order ASC');

    final documents = <ReadingDocument>[];
    for (final row in docRows) {
      final blockRows = await db.query(
        'document_blocks',
        where: 'document_id = ?',
        whereArgs: [row['id']],
        orderBy: 'order_index ASC',
      );
      final blocks = blockRows
          .map((b) => TextBlock(
                type: BlockType.values.byName(b['block_type'] as String),
                text: b['text'] as String,
                imageRef: b['image_ref'] as String?,
              ))
          .toList();

      documents.add(ReadingDocument(
        id: row['id'] as String,
        title: row['title'] as String,
        sourceType: DocumentSourceType.values.byName(row['source_type'] as String),
        blocks: blocks,
        importedAt: DateTime.parse(row['imported_at'] as String),
        sortOrder: row['sort_order'] as int,
      ));
    }
    return documents;
  }

  @override
  Future<void> removeFromLibrary(String documentId) async {
    final db = await AppDatabase.instance();
    await db.delete('documents', where: 'id = ?', whereArgs: [documentId]);
    // document_blocks/bookmarks/reading_history rows cascade via the
    // foreign key ON DELETE CASCADE declared in AppDatabase.
  }

  @override
  Future<void> reorderLibrary(List<String> orderedDocumentIds) async {
    final db = await AppDatabase.instance();
    await db.transaction((txn) async {
      for (var i = 0; i < orderedDocumentIds.length; i++) {
        await txn.update('documents', {'sort_order': i}, where: 'id = ?', whereArgs: [orderedDocumentIds[i]]);
      }
    });
  }
}
