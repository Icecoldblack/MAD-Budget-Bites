// Prices are whole numbers in minor units, so 650 means 6.50.
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

  factory Meal.fromMap(Map<String, Object?> map) {
    return Meal(
      id: map['id'] as int,
      name: map['name'] as String,
      venueNote: map['venueNote'] as String,
      cuisine: map['cuisine'] as String,
      estimatedPriceMinor: map['estimatedPriceMinor'] as int,
    );
  }

  // The id is left out because SQLite picks it.
  Map<String, Object?> toMap() {
    return {
      'name': name,
      'venueNote': venueNote,
      'cuisine': cuisine,
      'estimatedPriceMinor': estimatedPriceMinor,
    };
  }
}
