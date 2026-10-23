import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:budget_bites/data/meal_repository.dart';
import 'package:budget_bites/data/plan_repository.dart';
import 'package:budget_bites/data/purchase_repository.dart';
import 'package:budget_bites/main.dart';
import 'package:budget_bites/models/meal.dart';

import 'test_helpers.dart';

void main() {
  group('PlanRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('there is no plan at first', () async {
      expect(await PlanRepository().getPlannedMealId(), isNull);
      expect(await PlanRepository().getPlanStartedAt(), isNull);
    });

    test('startPlan saves the meal and the start time', () async {
      final before = DateTime.now();
      await PlanRepository().startPlan(7);

      // A new PlanRepository reads it back, like after a restart.
      expect(await PlanRepository().getPlannedMealId(), 7);
      final startedAt = (await PlanRepository().getPlanStartedAt())!;
      // The time is saved in whole milliseconds, so compare those.
      expect(
        startedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch),
      );
    });

    test('starting a new plan replaces the old one', () async {
      await PlanRepository().startPlan(7);
      await PlanRepository().startPlan(9);

      expect(await PlanRepository().getPlannedMealId(), 9);
    });

    test('clearPlan removes the plan', () async {
      await PlanRepository().startPlan(7);
      await PlanRepository().clearPlan();

      expect(await PlanRepository().getPlannedMealId(), isNull);
      expect(await PlanRepository().getPlanStartedAt(), isNull);
    });
  });

  group('Plan screens', () {
    late Database db;
    late MealRepository mealRepository;
    late PurchaseRepository purchaseRepository;

    setUp(() async {
      db = await openTestDatabase();
      mealRepository = MealRepository(db);
      purchaseRepository = PurchaseRepository(db);
      await mealRepository.insertMeal(
        const Meal(
          name: 'Burrito Bowl',
          venueNote: '',
          cuisine: 'Mexican',
          estimatedPriceMinor: 950,
        ),
      );
      await mealRepository.insertMeal(
        const Meal(
          name: 'Fried Rice',
          venueNote: '',
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

    Future<void> openTab(WidgetTester tester, String label) async {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
    }

    Future<void> planMeal(WidgetTester tester, String name) async {
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan this meal'));
      await tester.pumpAndSettle();
    }

    testWidgets('the Plan tab says "No plan yet" with no plan',
        (tester) async {
      await openApp(tester);
      await openTab(tester, 'Plan');

      expect(find.text('No plan yet'), findsOneWidget);
    });

    testWidgets('planning a meal shows it on the Plan tab', (tester) async {
      await openApp(tester);
      await planMeal(tester, 'Burrito Bowl');

      expect(find.text('This is your lunch plan'), findsOneWidget);
      expect(find.text('Plan this meal'), findsNothing);

      // Back to the catalog, then the Plan tab.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await openTab(tester, 'Plan');

      expect(find.text('Your plan'), findsOneWidget);
      expect(find.text('Burrito Bowl'), findsOneWidget);
      expect(find.text('This is your lunch plan'), findsOneWidget);
    });

    testWidgets('planning another meal asks before replacing the plan',
        (tester) async {
      await PlanRepository().startPlan(1);
      await openApp(tester);
      await planMeal(tester, 'Fried Rice');

      expect(find.text('Replace your plan?'), findsOneWidget);

      // Cancel keeps the old plan.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await PlanRepository().getPlannedMealId(), 1);

      // Replace switches the plan.
      await tester.tap(find.text('Plan this meal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();

      final friedRice = (await mealRepository.getAllMeals()).firstWhere(
        (meal) => meal.name == 'Fried Rice',
      );
      expect(await PlanRepository().getPlannedMealId(), friedRice.id);
      expect(find.text('This is your lunch plan'), findsOneWidget);
    });

    testWidgets('deleting the planned meal clears the plan', (tester) async {
      await openApp(tester);
      await planMeal(tester, 'Burrito Bowl');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await openTab(tester, 'Plan');

      await tester.tap(find.byTooltip('Delete meal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('No plan yet'), findsOneWidget);
      expect(await PlanRepository().getPlannedMealId(), isNull);
    });
  });
}
