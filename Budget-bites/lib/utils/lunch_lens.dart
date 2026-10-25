// Lunch Lens guesses the cost of the next purchase of a meal.
// It is a simple rule, not a trained model: the average of the last
// three purchases made before [before].

import '../models/purchase.dart';

// The three newest purchases before [before], newest first.
// Same time: the higher id was logged later, so it comes first.
// Negative prices are invalid and skipped.
List<Purchase> lastThreePurchases(List<Purchase> purchases, DateTime before) {
  List<Purchase> earlier = [];
  for (final purchase in purchases) {
    if (purchase.purchasedAt.isBefore(before) &&
        purchase.actualPriceMinor >= 0) {
      earlier.add(purchase);
    }
  }

  earlier.sort((a, b) {
    if (a.purchasedAt == b.purchasedAt) {
      return b.id!.compareTo(a.id!);
    }
    return b.purchasedAt.compareTo(a.purchasedAt);
  });

  if (earlier.length > 3) {
    return earlier.sublist(0, 3);
  }
  return earlier;
}

// The Lunch Lens estimate. Null means "Not enough history".
int? averageOfLastThree(List<Purchase> purchases, DateTime before) {
  final lastThree = lastThreePurchases(purchases, before);
  if (lastThree.length < 3) {
    return null;
  }

  final sum = lastThree[0].actualPriceMinor +
      lastThree[1].actualPriceMinor +
      lastThree[2].actualPriceMinor;

  // round() rounds .5 up for positive numbers.
  return (sum / 3).round();
}

// The baseline: the next price will be the same as the last one.
int? lastPriceBaseline(List<Purchase> purchases, DateTime before) {
  final lastThree = lastThreePurchases(purchases, before);
  if (lastThree.isEmpty) {
    return null;
  }
  return lastThree[0].actualPriceMinor;
}

// The alternative: the middle of the last three prices.
int? medianOfLastThree(List<Purchase> purchases, DateTime before) {
  final lastThree = lastThreePurchases(purchases, before);
  if (lastThree.length < 3) {
    return null;
  }

  List<int> prices = [
    lastThree[0].actualPriceMinor,
    lastThree[1].actualPriceMinor,
    lastThree[2].actualPriceMinor,
  ];
  prices.sort();
  return prices[1];
}
