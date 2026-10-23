import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/plan_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/main.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/models/purchase.dart';
import 'package:budget_bites/widgets/plan_progress.dart';
import 'package:budget_bites/widgets/receipt_card.dart';

import 'test_helpers.dart';

Purchase purchaseOf(int priceMinor) {
  return Purchase(
    id: 1,
    mealId: 1,
    purchasedAt: DateTime(2026, 10, 20),
    actualPriceMinor: priceMinor,
    note: '',
  );
}

Widget wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('ReceiptCard', () {
    testWidgets('before buying, it shows the plan only', (tester) async {
      await tester.pumpWidget(
        wrap(const ReceiptCard(plannedPriceMinor: 950, purchase: null)),
      );

      expect(find.text('Receipt'), findsOneWidget);
      expect(find.text('9.50'), findsOneWidget);
      expect(find.text('Not bought yet'), findsOneWidget);
    });

    testWidgets('paying more shows how much over plan', (tester) async {
      await tester.pumpWidget(
        wrap(ReceiptCard(plannedPriceMinor: 950, purchase: purchaseOf(975))),
      );

      expect(find.text('9.50'), findsOneWidget);
      expect(find.text('9.75'), findsOneWidget);
      expect(find.text('+0.25 over plan'), findsOneWidget);
    });

    testWidgets('paying less shows how much under plan', (tester) async {
      await tester.pumpWidget(
        wrap(ReceiptCard(plannedPriceMinor: 950, purchase: purchaseOf(800))),
      );

      expect(find.text('1.50 under plan'), findsOneWidget);
    });

    testWidgets('paying the same shows "Exactly on plan"', (tester) async {
      await tester.pumpWidget(
        wrap(ReceiptCard(plannedPriceMinor: 950, purchase: purchaseOf(950))),
      );

      expect(find.text('Exactly on plan'), findsOneWidget);
    });
  });

  group('PlanProgress', () {
    int checkMarks(WidgetTester tester) {
      return find.byIcon(Icons.check_circle).evaluate().length;
    }

    testWidgets('only "Planned" is done at first', (tester) async {
      await tester.pumpWidget(
        wrap(const PlanProgress(isBought: false, isFinished: false)),
      );

      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('Bought'), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);
      expect(checkMarks(tester), 1);
    });

    testWidgets('"Bought" is done after buying', (tester) async {
      await tester.pumpWidget(
        wrap(const PlanProgress(isBought: true, isFinished: false)),
      );

      expect(checkMarks(tester), 2);
    });

    testWidgets('every step is done when finished', (tester) async {
      await tester.pumpWidget(
        wrap(const PlanProgress(isBought: true, isFinished: true)),
      );

      expect(checkMarks(tester), 3);
    });
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

    Future<void> openPlanTab(WidgetTester tester) async {
      await tester.pumpWidget(
        BudgetBitesApp(
          mealRepository: mealRepository,
          purchaseRepository: purchaseRepository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, 'Plan'));
      await tester.pumpAndSettle();
    }

    testWidgets('no receipt or progress for a meal that is not planned',
        (tester) async {
      await tester.pumpWidget(
        BudgetBitesApp(
          mealRepository: mealRepository,
          purchaseRepository: purchaseRepository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Burrito Bowl'));
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptCard), findsNothing);
      expect(find.byType(PlanProgress), findsNothing);
    });

    testWidgets('logging a purchase fills in the receipt', (tester) async {
      await PlanRepository().startPlan(mealId);
      await openPlanTab(tester);

      expect(find.byType(ReceiptCard), findsOneWidget);
      expect(find.text('Not bought yet'), findsOneWidget);

      // The new cards push the button below the small test screen.
      await tester.scrollUntilVisible(find.text('Log purchase'), 200);
      await tester.tap(find.text('Log purchase'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price paid'),
        '9.75',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Log purchase').last);
      await tester.pumpAndSettle();

      expect(find.text('Not bought yet'), findsNothing);
      expect(find.text('+0.25 over plan'), findsOneWidget);

      // Scroll back up: the "Bought" step is now done.
      await tester.scrollUntilVisible(find.byType(PlanProgress), -200);
      final progress = tester.widget<PlanProgress>(find.byType(PlanProgress));
      expect(progress.isBought, isTrue);
    });

    testWidgets('a purchase from before the plan does not count',
        (tester) async {
      // Bought last week, then planned today.
      await purchaseRepository.insertPurchase(
        Purchase(
          mealId: mealId,
          purchasedAt: DateTime.now().subtract(const Duration(days: 7)),
          actualPriceMinor: 900,
          note: '',
        ),
      );
      await PlanRepository().startPlan(mealId);
      await openPlanTab(tester);

      expect(find.text('Not bought yet'), findsOneWidget);
    });
  });
}
