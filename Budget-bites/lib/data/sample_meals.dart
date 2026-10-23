import '../models/meal.dart';

/// Placeholder meals so the screens have something to show.
/// These go away once the SQLite Meal table is in place.
const List<Meal> sampleMeals = [
  Meal(
    id: 1,
    name: 'Chicken Burrito Bowl',
    venueNote: 'Student center, food court',
    cuisine: 'Mexican',
    estimatedPriceMinor: 950,
  ),
  Meal(
    id: 2,
    name: 'Veggie Fried Rice',
    venueNote: 'Library cafe',
    cuisine: 'Asian',
    estimatedPriceMinor: 650,
  ),
  Meal(
    id: 3,
    name: 'Turkey Sandwich',
    venueNote: 'Science building kiosk',
    cuisine: 'American',
    estimatedPriceMinor: 575,
  ),
];
