import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/screens/catalog_screen.dart';
import 'package:budget_bites/screens/history_screen.dart';
import 'package:budget_bites/widgets/meal_card.dart';

import 'test_helpers.dart';

void main() {
  late Database db;
  late MealRepository repository;

  setUp(() async {
    db = await openTestDatabase();
    repository = MealRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> addMeal(String name, String cuisine) async {
    await repository.insertMeal(Meal(
      name: name,
      venueNote: '',
      cuisine: cuisine,
      estimatedPriceMinor: 500,
    ));
  }

  Widget buildCatalog() {
    return MaterialApp(home: CatalogScreen(mealRepository: repository));
  }

  testWidgets('catalog shows an empty state when there are no meals',
      (tester) async {
    await tester.pumpWidget(buildCatalog());
    await tester.pumpAndSettle();

    expect(find.text('No meals yet'), findsOneWidget);
    expect(find.byType(MealCard), findsNothing);

    // The empty state button opens the meal form.
    await tester.tap(find.text('Add a meal'));
    await tester.pumpAndSettle();
    expect(find.text('Add Meal'), findsOneWidget);
  });

  testWidgets('cuisine filter narrows the meal list', (tester) async {
    await addMeal('Burrito Bowl', 'Mexican');
    await addMeal('Fried Rice', 'Asian');
    await addMeal('Sandwich', 'American');

    await tester.pumpWidget(buildCatalog());
    await tester.pumpAndSettle();
    expect(find.byType(MealCard), findsNWidgets(3));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Mexican'));
    await tester.pumpAndSettle();
    expect(find.byType(MealCard), findsOneWidget);
    expect(find.text('Burrito Bowl'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.byType(MealCard), findsNWidgets(3));
  });

  testWidgets('catalog shows "No meals match" when the filter has no meals',
      (tester) async {
    await addMeal('Pad Thai', 'Thai');
    await addMeal('Sandwich', 'American');

    await tester.pumpWidget(buildCatalog());
    await tester.pumpAndSettle();

    // Pick the Thai filter, then delete the only Thai meal.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Thai'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pad Thai'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No meals match'), findsOneWidget);

    await tester.tap(find.text('Show all meals'));
    await tester.pumpAndSettle();
    expect(find.text('Sandwich'), findsOneWidget);
  });

  testWidgets('history shows an empty state when there are no purchases',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));

    expect(find.text('No purchases yet'), findsOneWidget);
  });
}
