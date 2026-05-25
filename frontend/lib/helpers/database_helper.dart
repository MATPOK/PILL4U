import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medications.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        api_id INTEGER,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time TEXT NOT NULL,
        days TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        api_id INTEGER,
        medication_id INTEGER NOT NULL,
        medication_name TEXT NOT NULL,
        status TEXT NOT NULL,
        taken_at TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          api_id INTEGER,
          medication_id INTEGER NOT NULL,
          medication_name TEXT NOT NULL,
          status TEXT NOT NULL,
          taken_at TEXT NOT NULL
        )
      ''');
    }
  }

  // --- OBSŁUGA LEKÓW ---
  Future<int> insertSingleMedication(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('medications', row);
  }

  Future<void> insertMedications(List<dynamic> apiMeds) async {
    final db = await instance.database;
    final Batch batch = db.batch();

    for (var med in apiMeds) {
      final List<Map<String, dynamic>> existing = await db.query(
        'medications',
        where: 'api_id = ? OR (name = ? AND dosage = ? AND time = ? AND days = ?)',
        whereArgs: [med['id'], med['name'], med['dosage'], med['time'], med['days']],
      );

      if (existing.isEmpty) {
        batch.insert('medications', {
          'api_id': med['id'],
          'name': med['name'],
          'dosage': med['dosage'],
          'time': med['time'],
          'days': med['days'],
        });
      } else {
        if (existing.first['api_id'] == null && med['id'] != null) {
          batch.update(
            'medications',
            {'api_id': med['id']},
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        }
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getMedications() async {
    final db = await instance.database;
    return await db.query('medications');
  }

  Future<int> updateApiId(int localId, int apiId) async {
    final db = await instance.database;
    return await db.update(
      'medications',
      {'api_id': apiId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // --- OBSŁUGA HISTORII ---
  Future<int> insertHistoryItem(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('history', row);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedHistory() async {
    final db = await instance.database;
    return await db.query('history', where: 'api_id IS NULL');
  }

  Future<int> updateHistoryApiId(int localId, int apiId) async {
    final db = await instance.database;
    return await db.update(
      'history',
      {'api_id': apiId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<List<Map<String, dynamic>>> getTodayHistory() async {
    final db = await instance.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    return await db.query('history', where: 'taken_at LIKE ?', whereArgs: ['$todayStr%']);
  }

  Future<List<Map<String, dynamic>>> getAllHistory() async {
    final db = await instance.database;
    return await db.query('history');
  }

  // --- CZYSZCZENIE BAZY PRZY WYLOGOWANIU ---
  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('medications');
    await db.delete('history');
  }
}