import 'package:flutter_test/flutter_test.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/models/purchase.dart';
import 'package:budget_bites/utils/lunch_lens.dart';

import 'test_helpers.dart';

/// Makes a purchase of meal 1 for the tests.
Purchase purchase(int id, DateTime date, int priceMinor) {
  return Purchase(
    id: id,
    mealId: 1,
    purchasedAt: date,
    actualPriceMinor: priceMinor,
    note: '',
  );
}

/// How far off a guess was from the real price.
int errorOf(int guess, int actual) {
  return (guess - actual).abs();
}

void main() {
  // The "next" purchase happens on this day. Only purchases before it count.
  final nextDay = DateTime(2026, 10, 10);

  // ----- The five test cases from the proposal -----

  test('1. Normal: earlier 450, 600, 750 and next 650', () {
    final purchases = [
      purchase(1, DateTime(2026, 10, 1), 450),
      purchase(2, DateTime(2026, 10, 2), 600),
      purchase(3, DateTime(2026, 10, 3), 750),
    ];

    final estimate = averageOfLastThree(purchases, nextDay)!;
    final baseline = lastPriceBaseline(purchases, nextDay)!;

    expect(estimate, 600);
    expect(errorOf(estimate, 650), 50);
    expect(baseline, 750);
    expect(errorOf(baseline, 650), 100);

    // Changing 750 to 900 gives 650.
    purchases[2] = purchase(3, DateTime(2026, 10, 3), 900);
    expect(averageOfLastThree(purchases, nextDay), 650);
  });

  test('2. No data: only two earlier purchases', () {
    final purchases = [
      purchase(1, DateTime(2026, 10, 1), 450),
      purchase(2, DateTime(2026, 10, 2), 600),
    ];

    // Null means the card says "Not enough history".
    expect(averageOfLastThree(purchases, nextDay), isNull);
    expect(medianOfLastThree(purchases, nextDay), isNull);
    // The baseline only needs one purchase.
    expect(lastPriceBaseline(purchases, nextDay), 600);
  });

  test('2b. No data: no purchases at all', () {
    expect(averageOfLastThree([], nextDay), isNull);
    expect(lastPriceBaseline([], nextDay), isNull);
  });

  test('3. Invalid: a price of -100 is rejected and not saved', () async {
    final db = await openTestDatabase();
    final mealId = await MealRepository(db).insertMeal(
      const Meal(
        name: 'Soup',
        venueNote: '',
        cuisine: 'Soup',
        estimatedPriceMinor: 400,
      ),
    );
    final purchaseRepository = PurchaseRepository(db);

    // The database refuses a negative price.
    expect(
      () => purchaseRepository.insertPurchase(
        Purchase(
          mealId: mealId,
          purchasedAt: DateTime(2026, 10, 1),
          actualPriceMinor: -100,
          note: '',
        ),
      ),
      throwsA(anything),
    );
    expect(await purchaseRepository.getAllPurchases(), isEmpty);

    await db.close();
  });

  test('3b. Invalid: a price of -100 is not used by Lunch Lens', () {
    final purchases = [
      purchase(1, DateTime(2026, 10, 1), 450),
      purchase(2, DateTime(2026, 10, 2), 600),
      purchase(3, DateTime(2026, 10, 3), -100),
    ];

    // Only two valid purchases are left, so there is no estimate.
    expect(averageOfLastThree(purchases, nextDay), isNull);
  });

  test('4. Boundary: same time ordered by id, later purchase left out', () {
    final sameTime = DateTime(2026, 10, 2, 12, 0);
    final purchases = [
      purchase(1, sameTime, 300),
      // Same time as id 1, but logged after it, so it counts as newer.
      purchase(2, sameTime, 450),
      purchase(3, DateTime(2026, 10, 3), 500),
      purchase(4, DateTime(2026, 10, 4), 600),
      // Made after the next purchase, so it must not be used.
      purchase(5, DateTime(2026, 10, 20), 5000),
    ];

    final lastThree = lastThreePurchases(purchases, nextDay);
    expect(lastThree.map((p) => p.id), [4, 3, 2]);

    // (600 + 500 + 450) / 3 = 516.67, which rounds up to 517.
    expect(averageOfLastThree(purchases, nextDay), 517);
  });

  test('4b. Boundary: exactly three purchases is enough', () {
    final purchases = [
      purchase(1, DateTime(2026, 10, 1), 450),
      purchase(2, DateTime(2026, 10, 2), 450),
      purchase(3, DateTime(2026, 10, 3), 451),
    ];

    // (450 + 450 + 451) / 3 = 450.33, which rounds down to 450.
    expect(averageOfLastThree(purchases, nextDay), 450);
  });

  test('4c. Boundary: a purchase at the exact same moment is not "earlier"',
      () {
    final purchases = [
      purchase(1, DateTime(2026, 10, 1), 450),
      purchase(2, DateTime(2026, 10, 2), 600),
      purchase(3, nextDay, 750),
    ];

    expect(averageOfLastThree(purchases, nextDay), isNull);
  });

  test('5. Counterexample: earlier 500, 500, 2000 and next 520', () {
    final purchases = [
      purchase(1, DateTime(2026, 10, 1), 500),
      purchase(2, DateTime(2026, 10, 2), 500),
      purchase(3, DateTime(2026, 10, 3), 2000),
    ];

    final estimate = averageOfLastThree(purchases, nextDay)!;
    final baseline = lastPriceBaseline(purchases, nextDay)!;
    final median = medianOfLastThree(purchases, nextDay)!;

    expect(estimate, 1000);
    expect(errorOf(estimate, 520), 480);
    expect(baseline, 2000);
    expect(errorOf(baseline, 520), 1480);
    expect(median, 500);
    expect(errorOf(median, 520), 20);
  });

  // ----- Extra checks -----

  test('only the three most recent purchases are used', () {
    final purchases = [
      purchase(1, DateTime(2026, 10, 1), 9000),
      purchase(2, DateTime(2026, 10, 2), 400),
      purchase(3, DateTime(2026, 10, 3), 500),
      purchase(4, DateTime(2026, 10, 4), 600),
    ];

    expect(averageOfLastThree(purchases, nextDay), 500);
  });

  test('the order of the input list does not matter', () {
    final purchases = [
      purchase(3, DateTime(2026, 10, 3), 750),
      purchase(1, DateTime(2026, 10, 1), 450),
      purchase(2, DateTime(2026, 10, 2), 600),
    ];

    expect(lastThreePurchases(purchases, nextDay).map((p) => p.id), [3, 2, 1]);
    expect(lastPriceBaseline(purchases, nextDay), 750);
  });
}
