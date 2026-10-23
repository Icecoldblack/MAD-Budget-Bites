import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/data/sample_data.dart';
import 'package:budget_bites/main.dart';
import 'package:budget_bites/utils/lunch_lens.dart';

import 'test_helpers.dart';

void main() {
  late Database db;
  late MealRepository mealRepository;
  late PurchaseRepository purchaseRepository;

  setUp(() async {
    db = await openTestDatabase();
    mealRepository = MealRepository(db);
    purchaseRepository = PurchaseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('adds 6 meals and 10 purchases', () async {
    await addSampleData(mealRepository, purchaseRepository);

    expect((await mealRepository.getAllMeals()).length, 6);
    expect((await purchaseRepository.getAllPurchases()).length, 10);
    expect(
      await mealRepository.getCuisines(),
      ['American', 'Asian', 'Mexican', 'Soup', 'Thai'],
    );
  });

  test('the sample purchases give the Lunch Lens examples', () async {
    await addSampleData(mealRepository, purchaseRepository);
    final meals = await mealRepository.getAllMeals();
    final now = DateTime.now();

    Future<int?> estimateFor(String mealName) async {
      final meal = meals.firstWhere((meal) => meal.name == mealName);
      final purchases =
          await purchaseRepository.getPurchasesForMeal(meal.id!);
      return averageOfLastThree(purchases, now);
    }

    // 450, 600, 750.
    expect(await estimateFor('Veggie Fried Rice'), 600);
    // 500, 500, 2000: the outlier example.
    expect(await estimateFor('Turkey Sandwich'), 1000);
    // Only one purchase: "Not enough history".
    expect(await estimateFor('Pad Thai'), isNull);
    // No purchases.
    expect(await estimateFor('Tomato Soup'), isNull);
  });

  testWidgets('the Settings button loads the sample data', (tester) async {
    await tester.pumpWidget(
      BudgetBitesApp(
        mealRepository: mealRepository,
        purchaseRepository: purchaseRepository,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No meals yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load sample data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load'));
    await tester.pumpAndSettle();

    expect(find.text('Sample data added.'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Meals'));
    await tester.pumpAndSettle();
    // The first meal A to Z. The last ones are off the small test screen.
    expect(find.text('Bean Burrito'), findsOneWidget);
    // Pad Thai was bought today for 8.25, so 1.75 of 10.00 is left.
    expect(find.text('Budget left today: 1.75 of 10.00'), findsOneWidget);
  });

  testWidgets('cancel does not add anything', (tester) async {
    await tester.pumpWidget(
      BudgetBitesApp(
        mealRepository: mealRepository,
        purchaseRepository: purchaseRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load sample data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await mealRepository.getAllMeals(), isEmpty);
  });
}
