import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';
import '../models/history_entry.dart';

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

  Future<int> insertSingleMedication(Medication med) async {
    final db = await instance.database;
    return await db.insert('medications', med.toJson());
  }

  Future<void> insertMedications(List<Medication> apiMeds) async {
    final db = await instance.database;
    final Batch batch = db.batch();

    for (var med in apiMeds) {
      final List<Map<String, dynamic>> existing = await db.query(
        'medications',
        where: 'api_id = ? OR (name = ? AND dosage = ? AND time = ? AND days = ?)',
        whereArgs: [med.apiId, med.name, med.dosage, med.time, med.days],
      );

      if (existing.isEmpty) {
        batch.insert('medications', {
          'api_id': med.apiId,
          'name': med.name,
          'dosage': med.dosage,
          'time': med.time,
          'days': med.days,
        });
      } else {
        if (existing.first['api_id'] == null && med.apiId != null) {
          batch.update(
            'medications',
            {'api_id': med.apiId},
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        }
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<Medication>> getMedications() async {
    final db = await instance.database;
    final maps = await db.query('medications');
    return maps.map((m) => Medication.fromJson(m)).toList();
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

  Future<int> insertHistoryItem(HistoryEntry entry) async {
    final db = await instance.database;
    return await db.insert('history', entry.toJson());
  }

  Future<List<HistoryEntry>> getTodayHistoryForMedId(int medId) async {
    final db = await instance.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    final maps = await db.query(
        'history',
        where: 'medication_id = ? AND taken_at LIKE ? AND status != ?',
        whereArgs: [medId, '$todayStr%', 'DELETED'],
        limit: 1
    );
    return maps.map((m) => HistoryEntry.fromJson(m)).toList();
  }

  Future<int> softDeleteHistoryItem(int historyId) async {
    final db = await instance.database;
    return await db.update(
        'history',
        {'status': 'DELETED'},
        where: 'id = ?',
        whereArgs: [historyId]
    );
  }

  Future<List<HistoryEntry>> getUnsyncedHistory() async {
    final db = await instance.database;
    final maps = await db.query('history', where: 'api_id IS NULL AND status != ?', whereArgs: ['DELETED']);
    return maps.map((m) => HistoryEntry.fromJson(m)).toList();
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

  Future<List<HistoryEntry>> getTodayHistory() async {
    final db = await instance.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final maps = await db.query('history', where: 'taken_at LIKE ? AND status != ?', whereArgs: ['$todayStr%', 'DELETED']);
    return maps.map((m) => HistoryEntry.fromJson(m)).toList();
  }

  Future<List<HistoryEntry>> getAllHistory() async {
    final db = await instance.database;
    final maps = await db.query('history', where: 'status != ?', whereArgs: ['DELETED']);
    return maps.map((m) => HistoryEntry.fromJson(m)).toList();
  }

  Future<void> syncHistoryFromServer(List<HistoryEntry> apiHistory) async {
    final db = await instance.database;
    final Batch batch = db.batch();

    for (var h in apiHistory) {
      final dateStr = h.takenAt.substring(0, 10);

      final existing = await db.query(
        'history',
        where: '(api_id = ?) OR (medication_id = ? AND taken_at LIKE ? AND status = ?)',
        whereArgs: [h.apiId, h.medicationId, '$dateStr%', h.status],
      );

      final ghostShield = await db.query(
        'history',
        where: 'medication_id = ? AND taken_at LIKE ? AND status = ?',
        whereArgs: [h.medicationId, '$dateStr%', 'DELETED'],
      );

      if (existing.isEmpty && ghostShield.isEmpty) {
        batch.insert('history', h.toJson());
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('medications');
    await db.delete('history');
  }

  Future<List<Medication>> getMedicationGroup(String name, String dosage, String time) async {
    final db = await instance.database;
    final maps = await db.query('medications', where: 'name = ? AND dosage = ? AND time = ?', whereArgs: [name, dosage, time]);
    return maps.map((m) => Medication.fromJson(m)).toList();
  }

  Future<int> deleteMedicationGroup(String name, String dosage, String time) async {
    final db = await instance.database;
    return await db.delete('medications', where: 'name = ? AND dosage = ? AND time = ?', whereArgs: [name, dosage, time]);
  }

  Future<List<HistoryEntry>> getHistoryForDate(String dateStr) async {
    final db = await instance.database;
    final maps = await db.query(
        'history',
        where: 'taken_at LIKE ? AND status != ?',
        whereArgs: ['$dateStr%', 'DELETED'],
        orderBy: 'taken_at DESC'
    );
    return maps.map((m) => HistoryEntry.fromJson(m)).toList();
  }
}
