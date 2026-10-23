import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/models/purchase.dart';

import 'test_helpers.dart';

void main() {
  late Database db;
  late MealRepository mealRepository;
  late PurchaseRepository purchaseRepository;
  late int mealId;

  setUp(() async {
    db = await openTestDatabase();
    mealRepository = MealRepository(db);
    purchaseRepository = PurchaseRepository(db);

    // Every purchase needs a meal, so each test starts with one.
    mealId = await mealRepository.insertMeal(
      const Meal(
        name: 'Burrito Bowl',
        venueNote: '',
        cuisine: 'Mexican',
        estimatedPriceMinor: 950,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Purchase makePurchase(int priceMinor, DateTime date, {int? id}) {
    return Purchase(
      id: id,
      mealId: mealId,
      purchasedAt: date,
      actualPriceMinor: priceMinor,
      note: '',
    );
  }

  test('starts with no purchases', () async {
    expect(await purchaseRepository.getAllPurchases(), isEmpty);
  });

  test('insert saves a purchase and gives it an id', () async {
    final date = DateTime(2026, 10, 20, 12, 30);
    final id = await purchaseRepository.insertPurchase(
      Purchase(
        mealId: mealId,
        purchasedAt: date,
        actualPriceMinor: 450,
        note: 'With extra salsa',
      ),
    );

    final purchases = await purchaseRepository.getAllPurchases();
    expect(purchases.length, 1);
    expect(purchases.first.id, id);
    expect(purchases.first.mealId, mealId);
    expect(purchases.first.purchasedAt, date);
    expect(purchases.first.actualPriceMinor, 450);
    expect(purchases.first.note, 'With extra salsa');
  });

  test('purchases come back newest first, same time ordered by id', () async {
    final early = DateTime(2026, 10, 1);
    final late = DateTime(2026, 10, 5);

    final first = await purchaseRepository.insertPurchase(
      makePurchase(100, early),
    );
    final second = await purchaseRepository.insertPurchase(
      makePurchase(200, late),
    );
    final third = await purchaseRepository.insertPurchase(
      makePurchase(300, late),
    );

    final purchases = await purchaseRepository.getAllPurchases();
    expect(purchases.map((p) => p.id), [third, second, first]);
  });

  test('getPurchasesForMeal only returns that meal\'s purchases', () async {
    final otherMealId = await mealRepository.insertMeal(
      const Meal(
        name: 'Soup',
        venueNote: '',
        cuisine: 'Soup',
        estimatedPriceMinor: 400,
      ),
    );
    await purchaseRepository.insertPurchase(
      makePurchase(450, DateTime(2026, 10, 1)),
    );
    await purchaseRepository.insertPurchase(
      Purchase(
        mealId: otherMealId,
        purchasedAt: DateTime(2026, 10, 2),
        actualPriceMinor: 400,
        note: '',
      ),
    );

    final purchases = await purchaseRepository.getPurchasesForMeal(mealId);
    expect(purchases.length, 1);
    expect(purchases.first.actualPriceMinor, 450);
  });

  test('update changes a saved purchase', () async {
    final date = DateTime(2026, 10, 1);
    final id = await purchaseRepository.insertPurchase(makePurchase(600, date));

    await purchaseRepository.updatePurchase(makePurchase(550, date, id: id));

    final purchases = await purchaseRepository.getAllPurchases();
    expect(purchases.first.actualPriceMinor, 550);
  });

  test('delete removes a purchase', () async {
    final id = await purchaseRepository.insertPurchase(
      makePurchase(450, DateTime(2026, 10, 1)),
    );

    await purchaseRepository.deletePurchase(id);

    expect(await purchaseRepository.getAllPurchases(), isEmpty);
  });

  test('countPurchasesForMeal counts a meal\'s purchases', () async {
    expect(await purchaseRepository.countPurchasesForMeal(mealId), 0);

    await purchaseRepository.insertPurchase(
      makePurchase(450, DateTime(2026, 10, 1)),
    );
    await purchaseRepository.insertPurchase(
      makePurchase(600, DateTime(2026, 10, 2)),
    );

    expect(await purchaseRepository.countPurchasesForMeal(mealId), 2);
  });

  test('deleting a meal also deletes its purchases', () async {
    await purchaseRepository.insertPurchase(
      makePurchase(450, DateTime(2026, 10, 1)),
    );
    await purchaseRepository.insertPurchase(
      makePurchase(600, DateTime(2026, 10, 2)),
    );

    await mealRepository.deleteMeal(mealId);

    expect(await mealRepository.getAllMeals(), isEmpty);
    expect(await purchaseRepository.getAllPurchases(), isEmpty);
  });

  test('the database rejects a negative price', () async {
    expect(
      () => purchaseRepository.insertPurchase(
        makePurchase(-100, DateTime(2026, 10, 1)),
      ),
      throwsA(anything),
    );
    expect(await purchaseRepository.getAllPurchases(), isEmpty);
  });

  test('the database rejects a purchase for a meal that does not exist',
      () async {
    expect(
      () => purchaseRepository.insertPurchase(
        Purchase(
          mealId: 9999,
          purchasedAt: DateTime(2026, 10, 1),
          actualPriceMinor: 450,
          note: '',
        ),
      ),
      throwsA(anything),
    );
    expect(await purchaseRepository.getAllPurchases(), isEmpty);
  });
}
