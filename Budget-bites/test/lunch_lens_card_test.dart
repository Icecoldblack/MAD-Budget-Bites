import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/main.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/models/purchase.dart';
import 'package:budget_bites/widgets/lunch_lens_card.dart';

import 'test_helpers.dart';

Purchase purchase(int id, DateTime date, int priceMinor) {
  return Purchase(
    id: id,
    mealId: 1,
    purchasedAt: date,
    actualPriceMinor: priceMinor,
    note: '',
  );
}

Widget buildCard(List<Purchase> purchases) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: LunchLensCard(purchases: purchases)),
    ),
  );
}

void main() {
  testWidgets('says "Not enough history" with fewer than 3 purchases',
      (tester) async {
    await tester.pumpWidget(
      buildCard([
        purchase(1, DateTime(2026, 10, 1), 450),
        purchase(2, DateTime(2026, 10, 2), 600),
      ]),
    );

    expect(find.text('Lunch Lens'), findsOneWidget);
    expect(find.text('Not enough history'), findsOneWidget);
    expect(find.textContaining('You have 2 so far.'), findsOneWidget);
  });

  testWidgets('shows the estimate and the three amounts with dates',
      (tester) async {
    await tester.pumpWidget(
      buildCard([
        purchase(1, DateTime(2026, 10, 1), 450),
        purchase(2, DateTime(2026, 10, 2), 600),
        purchase(3, DateTime(2026, 10, 3), 900),
      ]),
    );

    // The estimate: (450 + 600 + 900) / 3 = 650.
    expect(find.text('6.50'), findsOneWidget);
    // The explanation.
    expect(
      find.text('Average of your last 3 purchases:'),
      findsOneWidget,
    );
    expect(find.textContaining('not a trained model'), findsOneWidget);
    // The three amounts and their dates.
    expect(find.text('4.50'), findsOneWidget);
    expect(find.text('6.00'), findsOneWidget);
    expect(find.text('9.00'), findsOneWidget);
    expect(find.text('2026-10-01'), findsOneWidget);
    expect(find.text('2026-10-02'), findsOneWidget);
    expect(find.text('2026-10-03'), findsOneWidget);
  });

  testWidgets('only the newest three purchases are listed', (tester) async {
    await tester.pumpWidget(
      buildCard([
        purchase(1, DateTime(2026, 9, 30), 9000),
        purchase(2, DateTime(2026, 10, 1), 450),
        purchase(3, DateTime(2026, 10, 2), 600),
        purchase(4, DateTime(2026, 10, 3), 900),
      ]),
    );

    expect(find.text('90.00'), findsNothing);
    expect(find.text('2026-09-30'), findsNothing);
    // (450 + 600 + 900) / 3 = 650. The old 90.00 is not used.
    expect(find.text('6.50'), findsOneWidget);
  });

  group('on the detail screen', () {
    late Database db;
    late MealRepository mealRepository;
    late PurchaseRepository purchaseRepository;
    late int mealId;

    setUp(() async {
      db = await openTestDatabase();
      mealRepository = MealRepository(db);
      purchaseRepository = PurchaseRepository(db);
      mealId = await mealRepository.insertMeal(
        const Meal(
          name: 'Tomato Soup',
          venueNote: '',
          cuisine: 'Soup',
          estimatedPriceMinor: 400,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> logPurchase(WidgetTester tester, String price) async {
      await tester.tap(find.text('Log purchase'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price paid'),
        price,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Log purchase').last);
      await tester.pumpAndSettle();
    }

    testWidgets('the card updates after each logged purchase', (tester) async {
      await purchaseRepository.insertPurchase(
        Purchase(
          mealId: mealId,
          purchasedAt: DateTime(2026, 10, 1),
          actualPriceMinor: 450,
          note: '',
        ),
      );
      await purchaseRepository.insertPurchase(
        Purchase(
          mealId: mealId,
          purchasedAt: DateTime(2026, 10, 2),
          actualPriceMinor: 600,
          note: '',
        ),
      );

      await tester.pumpWidget(
        BudgetBitesApp(
          mealRepository: mealRepository,
          purchaseRepository: purchaseRepository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tomato Soup'));
      await tester.pumpAndSettle();

      expect(find.text('Not enough history'), findsOneWidget);

      // The third purchase makes the estimate appear: (450+600+900)/3.
      await logPurchase(tester, '9.00');

      expect(find.text('Not enough history'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(LunchLensCard),
          matching: find.text('6.50'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the estimate does not fill in the price field',
        (tester) async {
      for (var day = 1; day <= 3; day++) {
        await purchaseRepository.insertPurchase(
          Purchase(
            mealId: mealId,
            purchasedAt: DateTime(2026, 10, day),
            actualPriceMinor: 600,
            note: '',
          ),
        );
      }

      await tester.pumpWidget(
        BudgetBitesApp(
          mealRepository: mealRepository,
          purchaseRepository: purchaseRepository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tomato Soup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log purchase'));
      await tester.pumpAndSettle();

      final priceField = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Price paid'),
          matching: find.byType(TextField),
        ),
      );
      expect(priceField.controller!.text, isEmpty);
    });
  });
}
