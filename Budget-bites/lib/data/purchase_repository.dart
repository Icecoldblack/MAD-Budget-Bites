import 'package:sqflite/sqflite.dart';

import '../models/purchase.dart';

/// Create, read, update, and delete for the PurchaseLog table.
class PurchaseRepository {
  final Database db;

  PurchaseRepository(this.db);

  /// Returns every purchase, newest first.
  /// Purchases at the same time are ordered by id.
  Future<List<Purchase>> getAllPurchases() async {
    final rows = await db.query(
      'PurchaseLog',
      orderBy: 'purchasedAt DESC, id DESC',
    );
    return rows.map((row) => Purchase.fromMap(row)).toList();
  }

  /// Returns the purchases from [from] up to (but not including) [to],
  /// newest first.
  Future<List<Purchase>> getPurchasesInRange(DateTime from, DateTime to) async {
    final rows = await db.query(
      'PurchaseLog',
      where: 'purchasedAt >= ? AND purchasedAt < ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'purchasedAt DESC, id DESC',
    );
    return rows.map((row) => Purchase.fromMap(row)).toList();
  }

  /// Adds up every purchase ever made, in minor units.
  Future<int> getTotalSpent() async {
    // COALESCE turns "no rows" (NULL) into 0.
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(actualPriceMinor), 0) AS total FROM PurchaseLog',
    );
    return rows.first['total'] as int;
  }

  /// Adds up the purchases from [from] up to (but not including) [to].
  Future<int> getTotalSpentInRange(DateTime from, DateTime to) async {
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(actualPriceMinor), 0) AS total FROM PurchaseLog '
      'WHERE purchasedAt >= ? AND purchasedAt < ?',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return rows.first['total'] as int;
  }

  /// Returns the purchases of one meal, newest first.
  Future<List<Purchase>> getPurchasesForMeal(int mealId) async {
    final rows = await db.query(
      'PurchaseLog',
      where: 'mealId = ?',
      whereArgs: [mealId],
      orderBy: 'purchasedAt DESC, id DESC',
    );
    return rows.map((row) => Purchase.fromMap(row)).toList();
  }

  /// How many purchases a meal has. Used to warn before deleting a meal.
  Future<int> countPurchasesForMeal(int mealId) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM PurchaseLog WHERE mealId = ?',
      [mealId],
    );
    return rows.first['total'] as int;
  }

  /// Saves a new purchase and returns the id SQLite gave it.
  Future<int> insertPurchase(Purchase purchase) async {
    return db.insert('PurchaseLog', purchase.toMap());
  }

  /// Saves changes to a purchase that is already in the table.
  Future<void> updatePurchase(Purchase purchase) async {
    await db.update(
      'PurchaseLog',
      purchase.toMap(),
      where: 'id = ?',
      whereArgs: [purchase.id],
    );
  }

  Future<void> deletePurchase(int id) async {
    await db.delete('PurchaseLog', where: 'id = ?', whereArgs: [id]);
  }
}
