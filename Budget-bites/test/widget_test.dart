import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_bites/main.dart';
import 'package:budget_bites/screens/meal_detail_screen.dart';
import 'package:budget_bites/widgets/meal_card.dart';

void main() {
  testWidgets('every tab in the bottom bar opens its screen', (tester) async {
    await tester.pumpWidget(const BudgetBitesApp());

    // Catalog is the first screen and lists meals with MealCard.
    expect(find.byType(MealCard), findsWidgets);

    final tabs = {
      'Add': 'Meal form',
      'Plan': 'Meal detail and plan',
      'History': 'No purchases yet',
      'Settings': 'Budget and display settings',
    };

    for (final entry in tabs.entries) {
      await tester.tap(find.widgetWithText(NavigationDestination, entry.key));
      await tester.pumpAndSettle();
      // IndexedStack keeps other tabs built, so check the visible one only.
      expect(find.text(entry.value, skipOffstage: true), findsOneWidget);
    }

    await tester.tap(find.widgetWithText(NavigationDestination, 'Meals'));
    await tester.pumpAndSettle();
    expect(find.byType(MealCard, skipOffstage: true), findsWidgets);
  });

  testWidgets('tapping a meal card opens its detail screen', (tester) async {
    await tester.pumpWidget(const BudgetBitesApp());

    await tester.tap(find.text('Veggie Fried Rice'));
    await tester.pumpAndSettle();

    // The detail screen reuses MealCard for the chosen meal.
    final detail = find.byType(MealDetailScreen, skipOffstage: true).last;
    expect(
      find.descendant(of: detail, matching: find.byType(MealCard)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: detail, matching: find.text('Library cafe')),
      findsOneWidget,
    );
  });
}
