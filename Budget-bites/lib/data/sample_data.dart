import '../models/meal.dart';
import '../models/purchase.dart';
import 'meal_repository.dart';
import 'plan_repository.dart';
import 'purchase_repository.dart';

// Lunch time, a number of days ago.
DateTime _daysAgo(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - days, 12, 30);
}

// Made-up data for the "Load sample data" button in Settings.
// - Veggie Fried Rice: 4.50, 6.00, 7.50, so Lunch Lens guesses 6.00.
// - Turkey Sandwich: 5.00, 5.00, 20.00, the outlier example.
// - Pad Thai: bought today and set as the lunch plan.
Future<void> addSampleData(
  MealRepository mealRepository,
  PurchaseRepository purchaseRepository,
) async {
  final burritoId = await mealRepository.insertMeal(
    const Meal(
      name: 'Chicken Burrito Bowl',
      venueNote: 'Student center food court',
      cuisine: 'Mexican',
      estimatedPriceMinor: 950,
    ),
  );
  await mealRepository.insertMeal(
    const Meal(
      name: 'Bean Burrito',
      venueNote: 'Student center food court',
      cuisine: 'Mexican',
      estimatedPriceMinor: 700,
    ),
  );
  final friedRiceId = await mealRepository.insertMeal(
    const Meal(
      name: 'Veggie Fried Rice',
      venueNote: 'Library cafe',
      cuisine: 'Asian',
      estimatedPriceMinor: 650,
    ),
  );
  final sandwichId = await mealRepository.insertMeal(
    const Meal(
      name: 'Turkey Sandwich',
      venueNote: 'Science building kiosk',
      cuisine: 'American',
      estimatedPriceMinor: 575,
    ),
  );
  final padThaiId = await mealRepository.insertMeal(
    const Meal(
      name: 'Pad Thai',
      venueNote: 'Food truck on Main St',
      cuisine: 'Thai',
      estimatedPriceMinor: 800,
    ),
  );
  await mealRepository.insertMeal(
    const Meal(
      name: 'Tomato Soup',
      venueNote: 'Dining hall',
      cuisine: 'Soup',
      estimatedPriceMinor: 400,
    ),
  );

  final now = DateTime.now();

  List<Purchase> purchases = [
    Purchase(
      mealId: burritoId,
      purchasedAt: _daysAgo(9),
      actualPriceMinor: 900,
      note: '',
    ),
    Purchase(
      mealId: burritoId,
      purchasedAt: _daysAgo(5),
      actualPriceMinor: 975,
      note: 'Added guac',
    ),
    Purchase(
      mealId: burritoId,
      purchasedAt: _daysAgo(1),
      actualPriceMinor: 950,
      note: '',
    ),
    Purchase(
      mealId: friedRiceId,
      purchasedAt: _daysAgo(6),
      actualPriceMinor: 450,
      note: 'Small size',
    ),
    Purchase(
      mealId: friedRiceId,
      purchasedAt: _daysAgo(4),
      actualPriceMinor: 600,
      note: '',
    ),
    Purchase(
      mealId: friedRiceId,
      purchasedAt: _daysAgo(2),
      actualPriceMinor: 750,
      note: 'Extra egg',
    ),
    Purchase(
      mealId: sandwichId,
      purchasedAt: _daysAgo(8),
      actualPriceMinor: 500,
      note: '',
    ),
    Purchase(
      mealId: sandwichId,
      purchasedAt: _daysAgo(7),
      actualPriceMinor: 500,
      note: '',
    ),
    Purchase(
      mealId: sandwichId,
      purchasedAt: _daysAgo(3),
      actualPriceMinor: 2000,
      note: 'Group order for 4',
    ),
    Purchase(
      mealId: padThaiId,
      purchasedAt: now.subtract(const Duration(minutes: 5)),
      actualPriceMinor: 825,
      note: '',
    ),
  ];

  for (final purchase in purchases) {
    await purchaseRepository.insertPurchase(purchase);
  }

  // The plan starts before today's Pad Thai purchase, so that purchase
  // fills in the receipt.
  await PlanRepository().startPlan(
    padThaiId,
    startedAt: now.subtract(const Duration(hours: 1)),
  );
}
