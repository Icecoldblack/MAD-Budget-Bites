import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/models/purchase.dart';
import 'package:budget_bites/widgets/purchase_dialog.dart';

import 'test_helpers.dart';

/// A purchase repository that takes 1 second to save, like a slow phone.
class SlowPurchaseRepository extends PurchaseRepository {
  SlowPurchaseRepository(super.db);

  @override
  Future<int> insertPurchase(Purchase purchase) async {
    await Future.delayed(const Duration(seconds: 1));
    return super.insertPurchase(purchase);
  }
}

void main() {
  late Database db;
  late SlowPurchaseRepository purchaseRepository;
  late int mealId;

  setUp(() async {
    db = await openTestDatabase();
    purchaseRepository = SlowPurchaseRepository(db);
    mealId = await MealRepository(db).insertMeal(
      const Meal(
        name: 'Soup',
        venueNote: '',
        cuisine: 'Soup',
        estimatedPriceMinor: 400,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PurchaseDialog(
            purchaseRepository: purchaseRepository,
            mealId: mealId,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price paid'),
      '4.50',
    );
  }

  testWidgets('tapping Log purchase twice saves only one purchase',
      (tester) async {
    await openDialog(tester);

    final logButton = find.widgetWithText(FilledButton, 'Log purchase');
    await tester.tap(logButton);
    // Tap again straight away, before the first save has finished.
    await tester.tap(logButton, warnIfMissed: false);

    // Let the slow save finish.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect((await purchaseRepository.getAllPurchases()).length, 1);
  });

  testWidgets('the button turns off and says Saving... while saving',
      (tester) async {
    await openDialog(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Log purchase'));
    await tester.pump();

    // While the save is running, the button is off.
    final savingButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Saving...'),
    );
    expect(savingButton.onPressed, isNull);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
