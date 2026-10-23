import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/plan_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/main.dart';
import 'package:budget_bites/models/meal.dart';
import 'package:budget_bites/models/purchase.dart';
import 'package:budget_bites/widgets/plan_progress.dart';

import 'test_helpers.dart';

void main() {
  group('PlanRepository finish', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('a new plan is not finished', () async {
      await PlanRepository().startPlan(1);
      expect(await PlanRepository().isPlanFinished(), isFalse);
    });

    test('finishPlan marks it finished and keeps the meal', () async {
      await PlanRepository().startPlan(1);
      await PlanRepository().finishPlan();

      // A new PlanRepository reads it back, like after a restart.
      expect(await PlanRepository().isPlanFinished(), isTrue);
      expect(await PlanRepository().getPlannedMealId(), 1);
    });

    test('starting a new plan is not finished again', () async {
      await PlanRepository().startPlan(1);
      await PlanRepository().finishPlan();
      await PlanRepository().startPlan(2);

      expect(await PlanRepository().isPlanFinished(), isFalse);
    });

    test('clearPlan also clears "finished"', () async {
      await PlanRepository().startPlan(1);
      await PlanRepository().finishPlan();
      await PlanRepository().clearPlan();

      expect(await PlanRepository().isPlanFinished(), isFalse);
      expect(await PlanRepository().getPlannedMealId(), isNull);
    });
  });

  group('Finish and Reset buttons', () {
    late Database db;
    late MealRepository mealRepository;
    late PurchaseRepository purchaseRepository;
    late int burritoId;

    setUp(() async {
      db = await openTestDatabase();
      mealRepository = MealRepository(db);
      purchaseRepository = PurchaseRepository(db);
      burritoId = await mealRepository.insertMeal(
        const Meal(
          name: 'Burrito Bowl',
          venueNote: '',
          cuisine: 'Mexican',
          estimatedPriceMinor: 950,
        ),
      );
      await PlanRepository().startPlan(burritoId);
    });

    tearDown(() async {
      await db.close();
    });

    /// Logs a purchase of the planned meal, made after the plan started.
    Future<void> buyPlannedMeal() async {
      await purchaseRepository.insertPurchase(
        Purchase(
          mealId: burritoId,
          purchasedAt: DateTime.now().add(const Duration(seconds: 1)),
          actualPriceMinor: 975,
          note: '',
        ),
      );
    }

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

    /// The buttons sit below the receipt, under the small test screen.
    Future<void> scrollToButtons(WidgetTester tester) async {
      await tester.scrollUntilVisible(find.text('Reset plan'), 200);
    }

    testWidgets('Finish is off until the meal is bought', (tester) async {
      await openPlanTab(tester);
      await scrollToButtons(tester);

      final finishButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Finish plan'),
      );
      expect(finishButton.onPressed, isNull);
      expect(
        find.text('Log a purchase of this meal to finish the plan.'),
        findsOneWidget,
      );
    });

    testWidgets('Finish completes every progress step', (tester) async {
      await buyPlannedMeal();
      await openPlanTab(tester);
      await scrollToButtons(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Finish plan'));
      await tester.pumpAndSettle();

      expect(find.text('Plan finished. Nice work!'), findsOneWidget);
      // Finish can't be tapped twice. Reset is still there.
      expect(find.text('Finish plan'), findsNothing);
      expect(find.text('Reset plan'), findsOneWidget);
      expect(await PlanRepository().isPlanFinished(), isTrue);

      await tester.scrollUntilVisible(find.byType(PlanProgress), -200);
      final progress = tester.widget<PlanProgress>(find.byType(PlanProgress));
      expect(progress.isBought, isTrue);
      expect(progress.isFinished, isTrue);
      expect(find.text('Plan finished'), findsOneWidget);
    });

    testWidgets('Reset asks first, then removes the plan', (tester) async {
      await buyPlannedMeal();
      await openPlanTab(tester);
      await scrollToButtons(tester);

      await tester.tap(find.text('Reset plan'));
      await tester.pumpAndSettle();
      expect(find.text('Reset plan?'), findsOneWidget);

      // Cancel keeps the plan.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await PlanRepository().getPlannedMealId(), burritoId);

      // Reset removes it.
      await tester.tap(find.text('Reset plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('No plan yet'), findsOneWidget);
      expect(await PlanRepository().getPlannedMealId(), isNull);
      // The purchase is kept.
      expect((await purchaseRepository.getAllPurchases()).length, 1);
    });

    testWidgets('a finished plan is replaced without asking', (tester) async {
      await PlanRepository().finishPlan();
      final friedRiceId = await mealRepository.insertMeal(
        const Meal(
          name: 'Fried Rice',
          venueNote: '',
          cuisine: 'Asian',
          estimatedPriceMinor: 650,
        ),
      );

      await tester.pumpWidget(
        BudgetBitesApp(
          mealRepository: mealRepository,
          purchaseRepository: purchaseRepository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fried Rice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan this meal'));
      await tester.pumpAndSettle();

      expect(find.text('Replace your plan?'), findsNothing);
      expect(await PlanRepository().getPlannedMealId(), friedRiceId);
      expect(await PlanRepository().isPlanFinished(), isFalse);
    });
  });
}
