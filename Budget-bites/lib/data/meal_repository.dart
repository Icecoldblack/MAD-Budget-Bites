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

  Future<void> deleteMeal(int id) async {
    await db.delete('Meal', where: 'id = ?', whereArgs: [id]);
  }
}
