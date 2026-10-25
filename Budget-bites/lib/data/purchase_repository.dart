import 'package:sqflite/sqflite.dart';

import '../models/purchase.dart';

// Every list is newest first. Purchases at the same time are ordered by id.
class PurchaseRepository {
  final Database db;

  PurchaseRepository(this.db);

  Future<List<Purchase>> getAllPurchases() async {
    final rows = await db.query(
      'PurchaseLog',
      orderBy: 'purchasedAt DESC, id DESC',
    );
    return rows.map((row) => Purchase.fromMap(row)).toList();
  }

  // From [from] up to, but not including, [to].
  Future<List<Purchase>> getPurchasesInRange(DateTime from, DateTime to) async {
    final rows = await db.query(
      'PurchaseLog',
      where: 'purchasedAt >= ? AND purchasedAt < ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'purchasedAt DESC, id DESC',
    );
    return rows.map((row) => Purchase.fromMap(row)).toList();
  }

  // COALESCE turns "no purchases" (NULL) into 0.
  Future<int> getTotalSpent() async {
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(actualPriceMinor), 0) AS total FROM PurchaseLog',
    );
    return rows.first['total'] as int;
  }

  Future<int> getTotalSpentInRange(DateTime from, DateTime to) async {
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(actualPriceMinor), 0) AS total FROM PurchaseLog '
      'WHERE purchasedAt >= ? AND purchasedAt < ?',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return rows.first['total'] as int;
  }

  Future<List<Purchase>> getPurchasesForMeal(int mealId) async {
    final rows = await db.query(
      'PurchaseLog',
      where: 'mealId = ?',
      whereArgs: [mealId],
      orderBy: 'purchasedAt DESC, id DESC',
    );
    return rows.map((row) => Purchase.fromMap(row)).toList();
  }

  Future<int> countPurchasesForMeal(int mealId) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM PurchaseLog WHERE mealId = ?',
      [mealId],
    );
    return rows.first['total'] as int;
  }

  // Returns the id SQLite gave the new purchase.
  Future<int> insertPurchase(Purchase purchase) async {
    return db.insert('PurchaseLog', purchase.toMap());
  }

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
