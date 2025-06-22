import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _database;
  String dbName = 'rental_properties.db';
  int dbVersion = 1;
  static String tableSession = 'seesion';
  static String tableUser = 'users';
  static String user = '''
      CREATE TABLE $tableUser (
        id INTEGER PRIMARY KEY,
        email TEXT,
        usernick TEXT,
        name TEXT,
        num_id TEXT,
        telefono TEXT NULL,
        photoPath TEXT NULL,
        tipo_usuario TEXT,
        tipo_cliente TEXT NULL,
        direccion TEXT NULL,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''';
  static String session = '''
      CREATE TABLE $tableSession (
        id INTEGER PRIMARY KEY,
        user_id INTEGER,
        status TEXT,
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES $tableUser (id)
      )
    ''';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute(user);
    await db.execute(session);
  }
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row);
  }
  Future<int> update(String table, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(table, row);
  }
  Future<bool> delete(String table, String id) async {
    final db = await database;
    int result = await db.delete(table, where: 'id = ?', whereArgs: [id]);
    return result > 0;
  }
  Future<List<Map<String, dynamic>>> query(String table, String? where, List<Object?>? whereArgs) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }
  Future<Map<String, dynamic>?> queryById(String table, String id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }
}