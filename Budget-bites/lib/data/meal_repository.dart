import 'package:sqflite/sqflite.dart';

import '../models/meal.dart';

/// Create, read, update, and delete for the Meal table.
class MealRepository {
  final Database db;

  MealRepository(this.db);

  /// Returns every meal, sorted by name.
  Future<List<Meal>> getAllMeals() async {
    final rows = await db.query('Meal', orderBy: 'name');
    return rows.map((row) => Meal.fromMap(row)).toList();
  }

  /// Returns only the meals of one cuisine, sorted by name.
  /// COLLATE NOCASE ignores upper and lower case, so "mexican" matches
  /// "Mexican".
  Future<List<Meal>> getMealsByCuisine(String cuisine) async {
    final rows = await db.query(
      'Meal',
      where: 'cuisine = ? COLLATE NOCASE',
      whereArgs: [cuisine],
      orderBy: 'name',
    );
    return rows.map((row) => Meal.fromMap(row)).toList();
  }

  /// Returns each cuisine once, sorted A to Z, for the filter chips.
  /// "mexican" and "Mexican" count as the same cuisine.
  Future<List<String>> getCuisines() async {
    final rows = await db.rawQuery(
      'SELECT cuisine FROM Meal '
      'GROUP BY cuisine COLLATE NOCASE '
      'ORDER BY cuisine COLLATE NOCASE',
    );
    return rows.map((row) => row['cuisine'] as String).toList();
  }

  /// Saves a new meal and returns the id SQLite gave it.
  Future<int> insertMeal(Meal meal) async {
    return db.insert('Meal', meal.toMap());
  }

  /// Saves changes to a meal that is already in the table.
  Future<void> updateMeal(Meal meal) async {
    await db.update(
      'Meal',
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }

  /// Deletes a meal and all of its purchases.
  /// Both deletes happen together, so we never keep half of them.
  Future<void> deleteMeal(int id) async {
    await db.transaction((txn) async {
      await txn.delete('PurchaseLog', where: 'mealId = ?', whereArgs: [id]);
      await txn.delete('Meal', where: 'id = ?', whereArgs: [id]);
    });
  }
}
