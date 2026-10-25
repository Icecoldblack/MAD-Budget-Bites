import 'package:sqflite/sqflite.dart';

import '../models/meal.dart';

class MealRepository {
  final Database db;

  MealRepository(this.db);

  Future<List<Meal>> getAllMeals() async {
    final rows = await db.query('Meal', orderBy: 'name');
    return rows.map((row) => Meal.fromMap(row)).toList();
  }

  // Returns null if the meal does not exist (for example, it was deleted).
  Future<Meal?> getMealById(int id) async {
    final rows = await db.query('Meal', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      return null;
    }
    return Meal.fromMap(rows.first);
  }

  // COLLATE NOCASE ignores upper and lower case, so "mexican" matches
  // "Mexican".
  Future<List<Meal>> getMealsByCuisine(String cuisine) async {
    final rows = await db.query(
      'Meal',
      where: 'cuisine = ? COLLATE NOCASE',
      whereArgs: [cuisine],
      orderBy: 'name',
    );
    return rows.map((row) => Meal.fromMap(row)).toList();
  }

  // Each cuisine once, A to Z. "mexican" and "Mexican" count as one.
  Future<List<String>> getCuisines() async {
    final rows = await db.rawQuery(
      'SELECT cuisine FROM Meal '
      'GROUP BY cuisine COLLATE NOCASE '
      'ORDER BY cuisine COLLATE NOCASE',
    );
    return rows.map((row) => row['cuisine'] as String).toList();
  }

  // Returns the id SQLite gave the new meal.
  Future<int> insertMeal(Meal meal) async {
    return db.insert('Meal', meal.toMap());
  }

  Future<void> updateMeal(Meal meal) async {
    await db.update(
      'Meal',
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }

  // Deletes the meal and its purchases together, so we never keep half.
  Future<void> deleteMeal(int id) async {
    await db.transaction((txn) async {
      await txn.delete('PurchaseLog', where: 'mealId = ?', whereArgs: [id]);
      await txn.delete('Meal', where: 'id = ?', whereArgs: [id]);
    });
  }
}
