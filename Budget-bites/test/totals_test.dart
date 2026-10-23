import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/database_helper.dart';
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
        name: 'Burrito Bowl',
        venueNote: '',
        cuisine: 'Mexican',
        estimatedPriceMinor: 500,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Purchase makePurchase(int priceMinor, DateTime date, {int? id}) {
    return Purchase(
      id: id,
      mealId: mealId,
      purchasedAt: date,
      actualPriceMinor: priceMinor,
      note: '',
    );
  }

  test('total is 0 when there are no purchases', () async {
    expect(await purchaseRepository.getTotalSpent(), 0);
  });

  // The test from the proposal.
  test('450 and 600 give 1050, 600 to 550 gives 1000, deleting 450 gives 550',
      () async {
    final firstDate = DateTime(2026, 10, 20);
    final secondDate = DateTime(2026, 10, 21);

    final firstId = await purchaseRepository.insertPurchase(
      makePurchase(450, firstDate),
    );
    final secondId = await purchaseRepository.insertPurchase(
      makePurchase(600, secondDate),
    );
    expect(await purchaseRepository.getTotalSpent(), 1050);

    await purchaseRepository.updatePurchase(
      makePurchase(550, secondDate, id: secondId),
    );
    expect(await purchaseRepository.getTotalSpent(), 1000);

    await purchaseRepository.deletePurchase(firstId);
    expect(await purchaseRepository.getTotalSpent(), 550);
  });

  test('the period total only counts purchases inside the dates', () async {
    await purchaseRepository.insertPurchase(
      makePurchase(100, DateTime(2026, 9, 30, 23, 59)),
    );
    await purchaseRepository.insertPurchase(
      makePurchase(200, DateTime(2026, 10, 1, 0, 0)),
    );
    await purchaseRepository.insertPurchase(
      makePurchase(300, DateTime(2026, 10, 15, 12, 0)),
    );
    await purchaseRepository.insertPurchase(
      makePurchase(400, DateTime(2026, 11, 1, 0, 0)),
    );

    // From October 1 up to (not including) November 1.
    final from = DateTime(2026, 10, 1);
    final to = DateTime(2026, 11, 1);

    expect(await purchaseRepository.getTotalSpentInRange(from, to), 500);

    final purchases = await purchaseRepository.getPurchasesInRange(from, to);
    expect(purchases.map((p) => p.actualPriceMinor), [300, 200]);
  });

  test('the period total is 0 when no purchases are inside the dates',
      () async {
    await purchaseRepository.insertPurchase(
      makePurchase(450, DateTime(2026, 10, 20)),
    );

    final total = await purchaseRepository.getTotalSpentInRange(
      DateTime(2026, 1, 1),
      DateTime(2026, 2, 1),
    );
    expect(total, 0);
  });

  test('the same totals show after the app restarts', () async {
    // Use a real file this time, so closing the database is like closing
    // the app.
    final folder = Directory.systemTemp.createTempSync('budget_bites_test');
    final path = join(folder.path, 'restart_test.db');

    var fileDb = await DatabaseHelper.openAppDatabase(path: path);
    var meals = MealRepository(fileDb);
    var purchases = PurchaseRepository(fileDb);
    final id = await meals.insertMeal(
      const Meal(
        name: 'Soup',
        venueNote: '',
        cuisine: 'Soup',
        estimatedPriceMinor: 400,
      ),
    );
    await purchases.insertPurchase(
      Purchase(
        mealId: id,
        purchasedAt: DateTime(2026, 10, 20),
        actualPriceMinor: 450,
        note: '',
      ),
    );
    await purchases.insertPurchase(
      Purchase(
        mealId: id,
        purchasedAt: DateTime(2026, 10, 21),
        actualPriceMinor: 600,
        note: '',
      ),
    );
    await fileDb.close();

    // "Restart": open the same file again.
    fileDb = await DatabaseHelper.openAppDatabase(path: path);
    purchases = PurchaseRepository(fileDb);
    expect(await purchases.getTotalSpent(), 1050);
    expect((await purchases.getAllPurchases()).length, 2);

    await fileDb.close();
    folder.deleteSync(recursive: true);
  });

  testWidgets('the history screen total follows edits and deletes',
      (tester) async {
    await purchaseRepository.insertPurchase(
      makePurchase(450, DateTime(2026, 10, 20)),
    );
    await purchaseRepository.insertPurchase(
      makePurchase(600, DateTime(2026, 10, 21)),
    );

    await tester.pumpWidget(
      BudgetBitesApp(
        mealRepository: mealRepository,
        purchaseRepository: purchaseRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'History'));
    await tester.pumpAndSettle();

    expect(find.text('Total spent'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    expect(find.text('10.50'), findsOneWidget);

    // Change 6.00 to 5.50.
    await tester.tap(find.widgetWithText(PurchaseTile, '6.00'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price paid'),
      '5.50',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('10.00'), findsOneWidget);

    // Delete the 4.50 purchase.
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(PurchaseTile, '4.50'),
        matching: find.byTooltip('Delete purchase'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // 5.50 shows twice: once as the total and once on the purchase.
    expect(find.text('5.50'), findsNWidgets(2));
    expect(find.byType(PurchaseTile), findsOneWidget);
  });
}
