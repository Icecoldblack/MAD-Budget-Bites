import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/plan_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/main.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/widgets/receipt_card.dart';

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
        estimatedPriceMinor: 950,
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

  testWidgets('the catalog has no extra + button; the Add tab is the way in',
      (tester) async {
    await openApp(tester);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.widgetWithText(NavigationDestination, 'Add'), findsOneWidget);
  });

  testWidgets('the budget line says where the budget comes from',
      (tester) async {
    await openApp(tester);

    expect(find.text('Set your daily budget in Settings'), findsOneWidget);
  });

  testWidgets('Log purchase is above the plan cards', (tester) async {
    await PlanRepository().startPlan(mealId);
    await openApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Plan'));
    await tester.pumpAndSettle();

    final buttonTop = tester.getTopLeft(find.text('Log purchase')).dy;
    final receiptTop = tester.getTopLeft(find.byType(ReceiptCard)).dy;
    expect(buttonTop, lessThan(receiptTop));
  });
}
