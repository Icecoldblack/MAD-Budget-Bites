/// A meal the student can plan to buy. Prices are whole numbers in minor
/// units, so 650 means 6.50.
class Meal {
  final int? id;
  final String name;
  final String venueNote;
  final String cuisine;
  final int estimatedPriceMinor;

  const Meal({
    this.id,
    required this.name,
    required this.venueNote,
    required this.cuisine,
    required this.estimatedPriceMinor,
  });
}
