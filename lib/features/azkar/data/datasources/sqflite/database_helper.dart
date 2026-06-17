import 'package:azkar_app/features/azkar/data/models/azkar_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('custom_azkar.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE custom_azkar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        count INTEGER NOT NULL,
        description TEXT,
        reference TEXT,
        zekr TEXT NOT NULL
      )
    ''');
  }

  // Insert a list of custom items inside a transaction for performance
  Future<void> insertCustomAzkar(List<AzkarModel> items) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert('custom_azkar', item.toJson());
    }

    await batch.commit(noResult: true);
  }

  // Fetch all user-generated custom entries
  Future<List<AzkarModel>> getCustomAzkar() async {
    final db = await instance.database;
    final result = await db.query('custom_azkar');

    return result.map((json) => AzkarModel.fromJson(json)).toList();
  }

  Future<int> deleteCustomCategory(String categoryName) async {
    final db = await instance.database;

    return await db.delete(
      'custom_azkar',
      where: 'category = ?',
      whereArgs: [categoryName],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
  }
}
