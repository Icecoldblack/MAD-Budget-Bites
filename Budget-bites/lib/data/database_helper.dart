import 'package:sqflite/sqflite.dart';

/// Opens the app's SQLite database and creates the tables the first time.
class DatabaseHelper {
  /// Version 1 had only the Meal table. Version 2 added PurchaseLog.
  static const int version = 2;

  /// Tests pass a different [path] so they get an empty in-memory database.
  static Future<Database> openAppDatabase({
    String path = 'budget_bites.db',
  }) async {
    return openDatabase(
      path,
      version: version,
      onConfigure: _turnOnForeignKeys,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  /// SQLite only checks that a purchase's mealId points to a real meal
  /// when foreign keys are turned on.
  static Future<void> _turnOnForeignKeys(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Runs on a brand new install.
  static Future<void> _createTables(Database db, int version) async {
    await _createMealTable(db);
    await _createPurchaseLogTable(db);
  }

  /// Runs when the app already has an older database on the device.
  static Future<void> _upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createPurchaseLogTable(db);
    }
  }

  static Future<void> _createMealTable(Database db) async {
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

  static Future<void> _createPurchaseLogTable(Database db) async {
    // mealId links each purchase to a row in the Meal table.
    await db.execute('''
      CREATE TABLE PurchaseLog (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mealId INTEGER NOT NULL REFERENCES Meal(id),
        purchasedAt INTEGER NOT NULL,
        actualPriceMinor INTEGER NOT NULL CHECK (actualPriceMinor >= 0),
        note TEXT NOT NULL
      )
    ''');
  }
}
