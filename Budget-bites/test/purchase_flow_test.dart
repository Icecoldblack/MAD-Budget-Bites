import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/main.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/models/purchase.dart';
import 'package:budget_bites/widgets/purchase_tile.dart';

import 'test_helpers.dart';

void main() {
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
        name: 'Veggie Fried Rice',
        venueNote: 'Library cafe',
        cuisine: 'Asian',
        estimatedPriceMinor: 650,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(
      BudgetBitesApp(
        mealRepository: mealRepository,
        purchaseRepository: purchaseRepository,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addPurchase(int priceMinor) async {
    await purchaseRepository.insertPurchase(
      Purchase(
        mealId: mealId,
        purchasedAt: DateTime(2026, 10, 20),
        actualPriceMinor: priceMinor,
        note: '',
      ),
    );
  }

  Future<void> openHistoryTab(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(NavigationDestination, 'History'));
    await tester.pumpAndSettle();
  }

  testWidgets('logging a purchase shows it on the detail and history screens',
      (tester) async {
    await openApp(tester);

    await tester.tap(find.text('Veggie Fried Rice'));
    await tester.pumpAndSettle();
    expect(find.text('No purchases of this meal yet.'), findsOneWidget);

    await tester.tap(find.text('Log purchase'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price paid'),
      '6.25',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Note (optional)'),
      'Extra egg',
    );
    // The dialog's button also says "Log purchase".
    await tester.tap(find.widgetWithText(FilledButton, 'Log purchase').last);
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseTile), findsOneWidget);
    expect(find.text('6.25'), findsOneWidget);

    // Go back to the catalog, then open History.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openHistoryTab(tester);

    expect(find.byType(PurchaseTile), findsOneWidget);
    expect(find.text('Veggie Fried Rice'), findsOneWidget);
    // Look inside the purchase row; the total card also shows 6.25.
    expect(find.widgetWithText(PurchaseTile, '6.25'), findsOneWidget);
  });

  testWidgets('the purchase form rejects a bad price', (tester) async {
    await openApp(tester);

    await tester.tap(find.text('Veggie Fried Rice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log purchase'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price paid'),
      '-1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log purchase').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a price like 6.50 (zero or more, up to 2 decimals).'),
      findsOneWidget,
    );
    expect(await purchaseRepository.getAllPurchases(), isEmpty);
  });

  testWidgets('a purchase can be edited from the history screen',
      (tester) async {
    await addPurchase(600);
    await openApp(tester);
    await openHistoryTab(tester);

    await tester.tap(find.byType(PurchaseTile));
    await tester.pumpAndSettle();
    expect(find.text('Edit purchase'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price paid'),
      '5.50',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    // Look inside the purchase row; the total card also shows 5.50.
    expect(find.widgetWithText(PurchaseTile, '5.50'), findsOneWidget);
    final purchases = await purchaseRepository.getAllPurchases();
    expect(purchases.first.actualPriceMinor, 550);
  });

  testWidgets('a purchase can be deleted from the history screen',
      (tester) async {
    await addPurchase(450);
    await openApp(tester);
    await openHistoryTab(tester);

    await tester.tap(find.byTooltip('Delete purchase'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No purchases yet'), findsOneWidget);
    expect(await purchaseRepository.getAllPurchases(), isEmpty);
  });

  testWidgets('deleting a meal says how many purchases go with it',
      (tester) async {
    await addPurchase(450);
    await addPurchase(600);
    await openApp(tester);

    await tester.tap(find.text('Veggie Fried Rice'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete meal'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Its 2 purchases will also be deleted.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(await mealRepository.getAllMeals(), isEmpty);
    expect(await purchaseRepository.getAllPurchases(), isEmpty);
  });
}
