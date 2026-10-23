import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_bites/data/sample_meals.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/screens/catalog_screen.dart';
import 'package:budget_bites/screens/history_screen.dart';
import 'package:budget_bites/widgets/meal_card.dart';

void main() {
  testWidgets('catalog shows an empty state when there are no meals',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CatalogScreen(meals: <Meal>[])),
    );

    expect(find.text('No meals yet'), findsOneWidget);
    expect(find.byType(MealCard), findsNothing);

    // The empty state button opens the meal form.
    await tester.tap(find.text('Add a meal'));
    await tester.pumpAndSettle();
    expect(find.text('Meal form'), findsOneWidget);
  });

  testWidgets('cuisine filter narrows the meal list', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CatalogScreen(meals: sampleMeals)),
    );
    expect(find.byType(MealCard), findsNWidgets(sampleMeals.length));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Mexican'));
    await tester.pumpAndSettle();
    expect(find.byType(MealCard), findsOneWidget);
    expect(find.text('Chicken Burrito Bowl'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.byType(MealCard), findsNWidgets(sampleMeals.length));
  });

  testWidgets('catalog shows "No meals match" when the filter has no meals',
      (tester) async {
    const padThai = Meal(
      id: 1,
      name: 'Pad Thai',
      venueNote: 'Food truck',
      cuisine: 'Thai',
      estimatedPriceMinor: 800,
    );
    const sandwich = Meal(
      id: 2,
      name: 'Turkey Sandwich',
      venueNote: 'Kiosk',
      cuisine: 'American',
      estimatedPriceMinor: 575,
    );

    // Pick the Thai filter, then the only Thai meal goes away.
    await tester.pumpWidget(
      const MaterialApp(home: CatalogScreen(meals: [padThai, sandwich])),
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Thai'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      const MaterialApp(home: CatalogScreen(meals: [sandwich])),
    );
    await tester.pumpAndSettle();
    expect(find.text('No meals match'), findsOneWidget);

    await tester.tap(find.text('Show all meals'));
    await tester.pumpAndSettle();
    expect(find.text('Turkey Sandwich'), findsOneWidget);
  });

  testWidgets('history shows an empty state when there are no purchases',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));

    expect(find.text('No purchases yet'), findsOneWidget);
  });
}
