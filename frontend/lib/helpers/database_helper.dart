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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE medications (
        id $idType,
        api_id INTEGER,
        name $textType,
        dosage $textType,
        time $textType,
        days $textType
      )
    ''');
  }

  Future<void> insertMedications(List<dynamic> meds) async {
    final db = await instance.database;
    final batch = db.batch();

    await db.delete('medications');

    for (var med in meds) {
      batch.insert('medications', {
        'api_id': med['id'],
        'name': med['name'],
        'dosage': med['dosage'],
        'time': med['time'],
        'days': med['days'],
      });
    }

    await batch.commit();
  }

  Future<void> insertSingleMedication(Map<String, dynamic> med) async {
    final db = await instance.database;
    await db.insert('medications', med);
  }

  Future<List<Map<String, dynamic>>> getMedications() async {
    final db = await instance.database;
    return await db.query('medications');
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete('medications');
  }
}