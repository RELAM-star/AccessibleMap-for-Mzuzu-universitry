// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('accessmap.db');
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
    // Locations table
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        description TEXT,
        has_wheelchair_ramp INTEGER DEFAULT 0,
        has_accessible_toilet INTEGER DEFAULT 0,
        has_accessible_parking INTEGER DEFAULT 0,
        has_elevator INTEGER DEFAULT 0,
        is_verified INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Reports table
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        location_name TEXT NOT NULL,
        issue_type TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    // Seed real Mzuni locations
    await _seedLocations(db);
  }

  Future _seedLocations(Database db) async {
    final locations = [
      {
        'name': 'Main Library',
        'category': 'Academic',
        'latitude': -11.4656,
        'longitude': 34.0207,
        'description': 'Central library with ramp at main entrance',
        'has_wheelchair_ramp': 1,
        'has_accessible_toilet': 1,
        'has_accessible_parking': 0,
        'has_elevator': 0,
        'is_verified': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Admin Block',
        'category': 'Administration',
        'latitude': -11.4648,
        'longitude': 34.0198,
        'description': 'Main administration building',
        'has_wheelchair_ramp': 1,
        'has_accessible_toilet': 1,
        'has_accessible_parking': 1,
        'has_elevator': 0,
        'is_verified': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Faculty of Science',
        'category': 'Academic',
        'latitude': -11.4662,
        'longitude': 34.0215,
        'description': 'Science and Technology faculty block',
        'has_wheelchair_ramp': 0,
        'has_accessible_toilet': 1,
        'has_accessible_parking': 0,
        'has_elevator': 0,
        'is_verified': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Student Centre',
        'category': 'Social',
        'latitude': -11.4670,
        'longitude': 34.0202,
        'description': 'MASU student centre and meeting point',
        'has_wheelchair_ramp': 1,
        'has_accessible_toilet': 1,
        'has_accessible_parking': 0,
        'has_elevator': 0,
        'is_verified': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Medical Centre',
        'category': 'Health',
        'latitude': -11.4640,
        'longitude': 34.0210,
        'description': 'Campus health centre - fully accessible',
        'has_wheelchair_ramp': 1,
        'has_accessible_toilet': 1,
        'has_accessible_parking': 1,
        'has_elevator': 0,
        'is_verified': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Main Cafeteria',
        'category': 'Dining',
        'latitude': -11.4675,
        'longitude': 34.0195,
        'description': 'Main student dining hall',
        'has_wheelchair_ramp': 1,
        'has_accessible_toilet': 0,
        'has_accessible_parking': 0,
        'has_elevator': 0,
        'is_verified': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Main Gate Bus Stop',
        'category': 'Transport',
        'latitude': -11.4630,
        'longitude': 34.0185,
        'description': 'Main entrance bus stop and transport hub',
        'has_wheelchair_ramp': 0,
        'has_accessible_toilet': 0,
        'has_accessible_parking': 0,
        'has_elevator': 0,
        'is_verified': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Livingstone Hostel',
        'category': 'Accommodation',
        'latitude': -11.4680,
        'longitude': 34.0220,
        'description': 'Student accommodation block',
        'has_wheelchair_ramp': 0,
        'has_accessible_toilet': 1,
        'has_accessible_parking': 0,
        'has_elevator': 0,
        'is_verified': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final location in locations) {
      await db.insert('locations', location);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}