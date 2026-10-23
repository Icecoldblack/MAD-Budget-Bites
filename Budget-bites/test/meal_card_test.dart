import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/utils/money.dart';
import 'package:budget_bites/widgets/meal_card.dart';

void main() {
  const meal = Meal(
    id: 1,
    name: 'Veggie Fried Rice',
    venueNote: 'Library cafe',
    cuisine: 'Asian',
    estimatedPriceMinor: 650,
  );

  test('formatMinor turns minor units into a price', () {
    expect(formatMinor(650), '6.50');
    expect(formatMinor(1050), '10.50');
    expect(formatMinor(5), '0.05');
    expect(formatMinor(0), '0.00');
    expect(formatMinor(-100), '-1.00');
  });

  testWidgets('MealCard shows the meal and reacts to taps', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MealCard(meal: meal, onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Veggie Fried Rice'), findsOneWidget);
    expect(find.text('Library cafe'), findsOneWidget);
    expect(find.text('Asian'), findsOneWidget);
    expect(find.text('6.50'), findsOneWidget);

    await tester.tap(find.byType(MealCard));
    expect(tapped, isTrue);
  });
}
