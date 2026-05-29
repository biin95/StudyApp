import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_record.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'study_app.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE file_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        category TEXT NOT NULL,
        format TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        is_studied INTEGER NOT NULL DEFAULT 0,
        is_favorited INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_opened_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE recent_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_id INTEGER NOT NULL,
        opened_at INTEGER NOT NULL,
        FOREIGN KEY (file_id) REFERENCES file_records(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE file_records ADD COLUMN is_studied INTEGER NOT NULL DEFAULT 0');
      await db.update('file_records', {'is_read': 0});
    }
    if (oldVersion < 3) {
      // Migrate existing 'exercise' files to 'exercise_practice'
      await db.update('file_records', {'category': 'exercise_practice'}, where: 'category = ?', whereArgs: ['exercise']);
    }
  }

  // ========== FileRecord CRUD ==========

  Future<int> insertFileRecord(FileRecord record) async {
    final db = await database;
    return await db.insert('file_records', record.toMap()..remove('id'));
  }

  Future<List<FileRecord>> getFileRecordsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'file_records',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => FileRecord.fromMap(map)).toList();
  }

  Future<FileRecord?> getFileRecordById(int id) async {
    final db = await database;
    final maps = await db.query(
      'file_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return FileRecord.fromMap(maps.first);
  }

  Future<int> updateFileRecord(FileRecord record) async {
    final db = await database;
    return await db.update(
      'file_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> markAsRead(int fileId) async {
    final db = await database;
    return await db.update(
      'file_records',
      {
        'is_read': 1,
        'last_opened_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [fileId],
    );
  }

  Future<int> toggleFavorite(int fileId, bool isFavorited) async {
    final db = await database;
    return await db.update(
      'file_records',
      {'is_favorited': isFavorited ? 1 : 0},
      where: 'id = ?',
      whereArgs: [fileId],
    );
  }

  Future<int> markAsStudied(int fileId, bool studied) async {
    final db = await database;
    return await db.update(
      'file_records',
      {'is_studied': studied ? 1 : 0},
      where: 'id = ?',
      whereArgs: [fileId],
    );
  }

  Future<int> resetAllReadMarks() async {
    final db = await database;
    return await db.update(
      'file_records',
      {'is_read': 0},
    );
  }

  Future<int> deleteFileRecord(int fileId) async {
    final db = await database;
    await db.delete(
      'recent_records',
      where: 'file_id = ?',
      whereArgs: [fileId],
    );
    return await db.delete(
      'file_records',
      where: 'id = ?',
      whereArgs: [fileId],
    );
  }

  Future<void> deleteFileRecords(List<int> fileIds) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final fileId in fileIds) {
        await txn.delete('recent_records', where: 'file_id = ?', whereArgs: [fileId]);
        await txn.delete('file_records', where: 'id = ?', whereArgs: [fileId]);
      }
    });
  }

  Future<List<FileRecord>> getFavoritedFiles() async {
    final db = await database;
    final maps = await db.query(
      'file_records',
      where: 'is_favorited = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => FileRecord.fromMap(map)).toList();
  }

  // ========== RecentRecord CRUD ==========

  Future<void> addRecentRecord(int fileId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if already exists, update if so
    final existing = await db.query(
      'recent_records',
      where: 'file_id = ?',
      whereArgs: [fileId],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'recent_records',
        {'opened_at': now},
        where: 'file_id = ?',
        whereArgs: [fileId],
      );
    } else {
      // Check count, delete oldest if >= 5
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM recent_records'),
      );
      if (count != null && count >= 5) {
        await db.rawDelete(
          'DELETE FROM recent_records WHERE id IN '
          '(SELECT id FROM recent_records ORDER BY opened_at ASC LIMIT ?)',
          [count - 4], // delete enough to make room for 1 new
        );
      }

      await db.insert('recent_records', {
        'file_id': fileId,
        'opened_at': now,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getRecentFilesWithRecords() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT r.id as recent_id, r.file_id, r.opened_at,
             f.id, f.name, f.path, f.category, f.format, 
             f.is_read, f.is_studied, f.is_favorited, f.created_at, f.last_opened_at
      FROM recent_records r
      INNER JOIN file_records f ON r.file_id = f.id
      ORDER BY r.opened_at DESC
      LIMIT 5
    ''');
    return results;
  }

  Future<int> removeRecentRecord(int recentId) async {
    final db = await database;
    return await db.delete(
      'recent_records',
      where: 'id = ?',
      whereArgs: [recentId],
    );
  }

  Future<int> deleteRecentRecordsByFileId(int fileId) async {
    final db = await database;
    return await db.delete(
      'recent_records',
      where: 'file_id = ?',
      whereArgs: [fileId],
    );
  }
}
