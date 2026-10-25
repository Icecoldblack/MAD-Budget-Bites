import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/main.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/widgets/meal_card.dart';

import 'test_helpers.dart';

void main() {
  late Database db;
  late MealRepository repository;
  late PurchaseRepository purchaseRepository;

  setUp(() async {
    db = await openTestDatabase();
    repository = MealRepository(db);
    purchaseRepository = PurchaseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> addFriedRice() async {
    await repository.insertMeal(
      const Meal(
        name: 'Veggie Fried Rice',
        venueNote: 'Library cafe',
        cuisine: 'Asian',
        estimatedPriceMinor: 650,
      ),
    );
  }

  testWidgets('every tab in the bottom bar opens its screen', (tester) async {
    await tester.pumpWidget(
      BudgetBitesApp(
        mealRepository: repository,
        purchaseRepository: purchaseRepository,
      ),
    );
    await tester.pumpAndSettle();

    // The catalog is the first screen. The database is empty.
    expect(find.text('No meals yet'), findsOneWidget);

    final tabs = {
      'Add': 'Add Meal',
      'Plan': 'No plan yet',
      'History': 'No purchases yet',
      'Settings': 'Daily lunch budget',
      'Meals': 'No meals yet',
    };

    for (final entry in tabs.entries) {
      await tester.tap(find.widgetWithText(NavigationDestination, entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('adding a meal from the Add tab shows it in the catalog', (
    tester,
  ) async {
    await tester.pumpWidget(
      BudgetBitesApp(
        mealRepository: repository,
        purchaseRepository: purchaseRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Add'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Meal name'),
      'Turkey Sandwich',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cuisine'),
      'American',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Estimated price'),
      '5.75',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Turkey Sandwich saved.'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Meals'));
    await tester.pumpAndSettle();

    expect(find.byType(MealCard), findsOneWidget);
    expect(find.text('Turkey Sandwich'), findsOneWidget);
    expect(find.text('5.75'), findsOneWidget);
  });

  testWidgets('the meal form rejects a bad price', (tester) async {
    await tester.pumpWidget(
      BudgetBitesApp(
        mealRepository: repository,
        purchaseRepository: purchaseRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Add'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Meal name'),
      'Soup',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cuisine'),
      'Soup',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Estimated price'),
      '-1',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a price like 6.50'),
      findsOneWidget,
    );
    expect(await repository.getAllMeals(), isEmpty);
  });

  testWidgets('a meal can be edited from its detail screen', (tester) async {
    await addFriedRice();
    await tester.pumpWidget(
      BudgetBitesApp(
        mealRepository: repository,
        purchaseRepository: purchaseRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Veggie Fried Rice'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit meal'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Meal'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Estimated price'),
      '7.25',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Back on the detail screen with the new price.
    expect(find.text('7.25'), findsOneWidget);

    final meals = await repository.getAllMeals();
    expect(meals.first.estimatedPriceMinor, 725);
  });

  testWidgets('a meal can be deleted after confirming', (tester) async {
    await addFriedRice();
    await tester.pumpWidget(
      BudgetBitesApp(
        mealRepository: repository,
        purchaseRepository: purchaseRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Veggie Fried Rice'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete meal'));
    await tester.pumpAndSettle();

    // Cancel keeps the meal.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await repository.getAllMeals()).length, 1);

    await tester.tap(find.byTooltip('Delete meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Back on the catalog, which is now empty.
    expect(find.text('No meals yet'), findsOneWidget);
    expect(await repository.getAllMeals(), isEmpty);
  });
}
