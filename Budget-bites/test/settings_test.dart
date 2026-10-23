import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/data/settings_repository.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/models/purchase.dart';
import 'package:budget_bites/screens/catalog_screen.dart';
import 'package:budget_bites/screens/settings_screen.dart';

import 'test_helpers.dart';

void main() {
  group('SettingsRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('the daily budget starts at 10.00', () async {
      expect(await SettingsRepository().getDailyBudget(), 1000);
    });

    test('a saved daily budget is read back', () async {
      await SettingsRepository().setDailyBudget(1250);

      // A new SettingsRepository reads the same saved value, like after
      // a restart.
      expect(await SettingsRepository().getDailyBudget(), 1250);
    });
  });

  group('SettingsScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows the budget as a number', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Daily lunch budget'), findsOneWidget);
      expect(find.text('10.00'), findsOneWidget);
    });

    testWidgets('shows a budget that was saved earlier', (tester) async {
      SharedPreferences.setMockInitialValues({
        SettingsRepository.dailyBudgetKey: 1500,
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('15.00'), findsOneWidget);
    });

    testWidgets('moving the slider saves the new budget', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Drag the slider all the way to the right: 30.00.
      await tester.drag(find.byType(Slider), const Offset(1000, 0));
      await tester.pumpAndSettle();

      expect(find.text('30.00'), findsOneWidget);
      expect(await SettingsRepository().getDailyBudget(), 3000);

      // Reopen the screen: the saved value is loaded again.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('30.00'), findsOneWidget);
    });
  });

  group('Budget left on the catalog', () {
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

    Future<void> addMealWithPurchaseToday(int priceMinor) async {
      final mealId = await mealRepository.insertMeal(
        const Meal(
          name: 'Soup',
          venueNote: '',
          cuisine: 'Soup',
          estimatedPriceMinor: 400,
        ),
      );
      await purchaseRepository.insertPurchase(
        Purchase(
          mealId: mealId,
          purchasedAt: DateTime.now(),
          actualPriceMinor: priceMinor,
          note: '',
        ),
      );
    }

    Widget buildCatalog() {
      return MaterialApp(
        home: CatalogScreen(
          mealRepository: mealRepository,
          purchaseRepository: purchaseRepository,
        ),
      );
    }

    testWidgets('budget minus today\'s spending is shown', (tester) async {
      await SettingsRepository().setDailyBudget(1000);
      await addMealWithPurchaseToday(625);

      await tester.pumpWidget(buildCatalog());
      await tester.pumpAndSettle();

      expect(find.text('Budget left today: 3.75 of 10.00'), findsOneWidget);
    });

    testWidgets('overspending shows a negative amount', (tester) async {
      await SettingsRepository().setDailyBudget(500);
      await addMealWithPurchaseToday(650);

      await tester.pumpWidget(buildCatalog());
      await tester.pumpAndSettle();

      expect(find.text('Budget left today: -1.50 of 5.00'), findsOneWidget);
    });
  });
}
