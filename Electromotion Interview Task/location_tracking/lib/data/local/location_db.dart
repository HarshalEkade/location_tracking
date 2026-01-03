import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/location_model.dart';

class LocationDatabase {
  static final LocationDatabase instance = LocationDatabase._init();
  static Database? _database;

  LocationDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('locations.db');
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

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const realType = 'REAL NOT NULL';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE locations (
        id $idType,
        latitude $realType,
        longitude $realType,
        timestamp $textType,
        userId $textTypeNullable,
        sessionId $textTypeNullable,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<String> insert(LocationModel location) async {
    final db = await database;
    await db.insert(
      'locations',
      {
        ...location.toMap(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return location.id;
  }

  Future<List<LocationModel>> getUnsyncedLocations() async {
    final db = await database;
    const orderBy = 'timestamp ASC';
    final result = await db.query(
      'locations',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: orderBy,
    );

    return result.map((json) => LocationModel.fromMap(json)).toList();
  }

  Future<void> markAsSynced(List<String> ids) async {
    final db = await database;
    if (ids.isEmpty) return;

    final placeholders = ids.map((e) => '?').join(',');
    await db.rawUpdate(
      'UPDATE locations SET synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  Future<List<LocationModel>> getAllLocations({int? limit}) async {
    final db = await database;
    final result = await db.query(
      'locations',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return result.map((json) => LocationModel.fromMap(json)).toList();
  }

  Future<void> deleteSyncedLocations() async {
    final db = await database;
    await db.delete(
      'locations',
      where: 'synced = ?',
      whereArgs: [1],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('locations');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}





