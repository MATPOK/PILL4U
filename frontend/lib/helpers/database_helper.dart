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
      version: 3,
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
        days TEXT NOT NULL,
        pending_delete INTEGER NOT NULL DEFAULT 0
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
    for (int i = oldVersion; i < newVersion; i++) {
      switch (i) {
        case 1:
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
          break;
        case 2:
        // Migracja v2 -> v3: kolejka leków usuniętych w trybie offline.
          await db.execute('ALTER TABLE medications ADD COLUMN pending_delete INTEGER NOT NULL DEFAULT 0');
          break;
        case 3:
        // Kolejne wersje...
          break;
      }
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
        where: 'name = ? AND dosage = ? AND time = ? AND days = ?',
        whereArgs: [med.name, med.dosage, med.time, med.days],
      );

      if (existing.isEmpty) {
        batch.insert('medications', med.toJson());
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
    // Pomijamy leki oznaczone do usunięcia (czekają na synchronizację z serwerem).
    final maps = await db.query('medications', where: 'pending_delete = 0');
    return maps.map((m) => Medication.fromJson(m)).toList();
  }

  // Oznacza zsynchronizowany lek jako usunięty offline, znika z UI, czeka na usunięcie z serwera.
  Future<int> markMedicationPendingDelete(int localId) async {
    final db = await instance.database;
    return await db.update('medications', {'pending_delete': 1}, where: 'id = ?', whereArgs: [localId]);
  }

  // Twarde usunięcie wiersza leku (gdy serwer już potwierdził usunięcie lub lek nigdy tam nie trafił).
  Future<int> deleteMedicationById(int localId) async {
    final db = await instance.database;
    return await db.delete('medications', where: 'id = ?', whereArgs: [localId]);
  }

  // Leki czekające na dosłanie usunięcia do serwera.
  Future<List<Medication>> getMedicationsPendingDelete() async {
    final db = await instance.database;
    final maps = await db.query('medications', where: 'pending_delete = 1');
    return maps.map((m) => Medication.fromJson(m)).toList();
  }

  Future<Medication?> getMedicationById(int id) async {
    final db = await instance.database;
    final maps = await db.query('medications', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Medication.fromJson(maps.first);
    return null;
  }

  Future<int> updateApiId(int localId, int apiId) async {
    final db = await instance.database;
    return await db.update('medications', {'api_id': apiId}, where: 'id = ?', whereArgs: [localId]);
  }

  Future<int> insertHistoryItem(HistoryEntry entry) async {
    final db = await instance.database;
    return await db.insert('history', entry.toJson());
  }

  Future<List<HistoryEntry>> getTodayHistoryForMedIds(int localId, int? apiId) async {
    final db = await instance.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final maps = await db.query(
      'history',
      where: '(medication_id = ? OR medication_id = ?) AND taken_at LIKE ? AND status != ?',
      whereArgs: [localId, apiId ?? -1, '$todayStr%', 'DELETED'],
    );
    return maps.map((m) => HistoryEntry.fromJson(m)).toList();
  }

  Future<int> softDeleteHistoryItem(int historyId) async {
    final db = await instance.database;
    return await db.update('history', {'status': 'DELETED'}, where: 'id = ?', whereArgs: [historyId]);
  }

  // Twarde usunięcie wpisu historii (gdy serwer już potwierdził usunięcie).
  Future<int> deleteHistoryItemById(int historyId) async {
    final db = await instance.database;
    return await db.delete('history', where: 'id = ?', whereArgs: [historyId]);
  }

  // Wpisy cofnięte offline, które wciąż istnieją na serwerze i czekają na dosłanie usunięcia.
  Future<List<HistoryEntry>> getHistoryPendingServerDelete() async {
    final db = await instance.database;
    final maps = await db.query('history', where: "status = 'DELETED' AND api_id > 0");
    return maps.map((m) => HistoryEntry.fromJson(m)).toList();
  }

  Future<List<HistoryEntry>> getUnsyncedHistory() async {
    final db = await instance.database;
    final maps = await db.query('history', where: 'api_id IS NULL AND status != ?', whereArgs: ['DELETED']);
    return maps.map((m) => HistoryEntry.fromJson(m)).toList();
  }

  Future<int> updateHistoryApiId(int localId, int apiId) async {
    final db = await instance.database;
    return await db.update('history', {'api_id': apiId}, where: 'id = ?', whereArgs: [localId]);
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