import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change default factory
    databaseFactory = databaseFactoryFfi;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        value TEXT NOT NULL,
        parent TEXT
      )
    ''');
  }

  Future<void> insertItem(String id, String type, String value,
      {String? parent}) async {
    final db = await database;
    await db.insert(
      'items',
      {
        'id': id,
        'type': type,
        'value': value,
        'parent': parent,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace, // This will replace existing entries
    );
  }

  Future<void> clearAllItems() async {
    final db = await database;
    await db.delete('items');
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return db.query('items');
  }
}
