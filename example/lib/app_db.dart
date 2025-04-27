import 'dart:async';
import 'dart:io';
import 'fake_point.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

class AppDatabase {
  static final AppDatabase _appDatabase = AppDatabase._internal();

  AppDatabase._internal();

  Database? _database;

  static AppDatabase get() {
    return _appDatabase;
  }

  final _lock = Lock();

  Future<Database> getDb() async {
    if (_database == null) {
      await _lock.synchronized(() async {
        if (_database == null) {
          await _init();
        }
      });
    }
    return _database!;
  }

  Future<void> _init() async {
    print("AppDatabase: init database");
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "clustering.db");
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await _createFakePointsTable(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        await db.execute("DROP TABLE IF EXISTS ${FakePoint.tblFakePoints}");
        await _createFakePointsTable(db);
      },
    );
  }

  Future<void> _createFakePointsTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${FakePoint.tblFakePoints} (
        ${FakePoint.dbId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${FakePoint.dbGeohash} TEXT,
        ${FakePoint.dbLat} REAL,
        ${FakePoint.dbLong} REAL
      )
    ''');
  }

  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      print("Database closed");
    }
  }
}
