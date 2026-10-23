import 'package:sqflite/sqflite.dart';

/// Opens the app's SQLite database and creates the tables the first time.
class DatabaseHelper {
  /// Tests pass a different [path] so they get an empty in-memory database.
  static Future<Database> openAppDatabase({
    String path = 'budget_bites.db',
  }) async {
    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    // Prices are whole numbers in minor units and can't be negative.
    await db.execute('''
      CREATE TABLE Meal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        venueNote TEXT NOT NULL,
        cuisine TEXT NOT NULL,
        estimatedPriceMinor INTEGER NOT NULL CHECK (estimatedPriceMinor >= 0)
      )
    ''');
  }
}
