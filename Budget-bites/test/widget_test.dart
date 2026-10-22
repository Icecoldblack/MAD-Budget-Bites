import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_bites/main.dart';

void main() {
  testWidgets('every tab in the bottom bar opens its screen', (tester) async {
    await tester.pumpWidget(const BudgetBitesApp());

    // Catalog is the first screen.
    expect(find.text('Meal catalog'), findsOneWidget);

    final tabs = {
      'Add': 'Meal form',
      'Plan': 'Meal detail and plan',
      'History': 'Purchase history',
      'Settings': 'Budget and display settings',
      'Meals': 'Meal catalog',
    };

    for (final entry in tabs.entries) {
      await tester.tap(find.widgetWithText(NavigationDestination, entry.key));
      await tester.pumpAndSettle();
      // IndexedStack keeps other tabs built, so check the visible one only.
      expect(find.text(entry.value, skipOffstage: true), findsOneWidget);
    }
  });
}
