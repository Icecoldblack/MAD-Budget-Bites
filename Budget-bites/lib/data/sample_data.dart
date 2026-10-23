import '../models/meal.dart';
import '../models/purchase.dart';
import 'meal_repository.dart';
import 'purchase_repository.dart';

/// Adds made-up meals and purchases so every screen has something to show.
/// Used by the "Load sample data" button in Settings.
///
/// The purchases are set up to show each feature:
/// - Veggie Fried Rice: 4.50, 6.00, 7.50, so Lunch Lens guesses 6.00.
/// - Turkey Sandwich: 5.00, 5.00, 20.00, the outlier example (guess 10.00).
/// - Pad Thai: one purchase today, so "Budget left today" goes down, and
///   Lunch Lens says "Not enough history".
/// - Tomato Soup and Bean Burrito: no purchases yet.
Future<void> addSampleData(
  MealRepository mealRepository,
  PurchaseRepository purchaseRepository,
) async {
  final now = DateTime.now();

  // Lunch time, a number of days ago.
  DateTime daysAgo(int days) {
    return DateTime(now.year, now.month, now.day - days, 12, 30);
  }

  // Meals.
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

  // Purchases.
  final purchases = [
    Purchase(
      mealId: burritoId,
      purchasedAt: daysAgo(9),
      actualPriceMinor: 900,
      note: '',
    ),
    Purchase(
      mealId: burritoId,
      purchasedAt: daysAgo(5),
      actualPriceMinor: 975,
      note: 'Added guac',
    ),
    Purchase(
      mealId: burritoId,
      purchasedAt: daysAgo(1),
      actualPriceMinor: 950,
      note: '',
    ),
    Purchase(
      mealId: friedRiceId,
      purchasedAt: daysAgo(6),
      actualPriceMinor: 450,
      note: 'Small size',
    ),
    Purchase(
      mealId: friedRiceId,
      purchasedAt: daysAgo(4),
      actualPriceMinor: 600,
      note: '',
    ),
    Purchase(
      mealId: friedRiceId,
      purchasedAt: daysAgo(2),
      actualPriceMinor: 750,
      note: 'Extra egg',
    ),
    Purchase(
      mealId: sandwichId,
      purchasedAt: daysAgo(8),
      actualPriceMinor: 500,
      note: '',
    ),
    Purchase(
      mealId: sandwichId,
      purchasedAt: daysAgo(7),
      actualPriceMinor: 500,
      note: '',
    ),
    Purchase(
      mealId: sandwichId,
      purchasedAt: daysAgo(3),
      actualPriceMinor: 2000,
      note: 'Group order for 4',
    ),
    // A few minutes ago, so it counts as today.
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
}
