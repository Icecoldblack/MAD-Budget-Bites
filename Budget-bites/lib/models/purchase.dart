// The price is what was actually paid, in minor units (650 means 6.50).
// The date is stored in the database as milliseconds since 1970.
class Purchase {
  final int? id;
  final int mealId;
  final DateTime purchasedAt;
  final int actualPriceMinor;
  final String note;

  const Purchase({
    this.id,
    required this.mealId,
    required this.purchasedAt,
    required this.actualPriceMinor,
    required this.note,
  });

  factory Purchase.fromMap(Map<String, Object?> map) {
    return Purchase(
      id: map['id'] as int,
      mealId: map['mealId'] as int,
      purchasedAt:
          DateTime.fromMillisecondsSinceEpoch(map['purchasedAt'] as int),
      actualPriceMinor: map['actualPriceMinor'] as int,
      note: map['note'] as String,
    );
  }

  // The id is left out because SQLite picks it.
  Map<String, Object?> toMap() {
    return {
      'mealId': mealId,
      'purchasedAt': purchasedAt.millisecondsSinceEpoch,
      'actualPriceMinor': actualPriceMinor,
      'note': note,
    };
  }
}
