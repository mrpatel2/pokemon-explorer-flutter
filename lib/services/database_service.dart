import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pokemon.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  // opens the database
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pokemon_favorites.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        //runs only on first app launch
        return db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            imageUrl TEXT NOT NULL,
            types TEXT NOT NULL,
            savedAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Load all saved favorites and has the newest first
  Future<List<Pokemon>> getAllFavorites() async {
    final db = await database;
    final maps = await db.query('favorites', orderBy: 'savedAt DESC');
    return maps.map((map) => Pokemon.fromMap(map)).toList();
  }

  // Check if a pokemon is already saved
  Future<bool> isFavorite(int id) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }

  // Save a pokemon to favorites
  Future<void> addFavorite(Pokemon pokemon) async {
    final db = await database;
    await db.insert('favorites', {
      ...pokemon.toMap(),
      'savedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Delete one pokemon by ID
  Future<void> removeFavorite(int id) async {
    final db = await database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  // Delete favorites
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('favorites');
  }
}
