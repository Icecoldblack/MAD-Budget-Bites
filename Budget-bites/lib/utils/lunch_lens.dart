// Lunch Lens: guesses what the next purchase of a meal will cost.
//
// It is a simple rule, not a trained model:
//   estimate = the average of the last three purchases of the meal.
//
// Only purchases made before [before] are used, so a later purchase
// can never affect the guess for an earlier one.

import '../models/purchase.dart';

/// Returns the three most recent purchases made before [before],
/// newest first. Returns fewer than three if there aren't enough.
///
/// Purchases made at the same time are ordered by id: a higher id was
/// logged later. Negative prices are not valid, so they are skipped.
List<Purchase> lastThreePurchases(List<Purchase> purchases, DateTime before) {
  final earlier = <Purchase>[];
  for (final purchase in purchases) {
    if (purchase.purchasedAt.isBefore(before) &&
        purchase.actualPriceMinor >= 0) {
      earlier.add(purchase);
    }
  }

  // Newest first. If two purchases have the same time, the higher id
  // comes first.
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

/// The Lunch Lens estimate: the average of the last three purchases,
/// rounded to the nearest whole unit (halves round up).
///
/// Returns null when there are fewer than three earlier purchases.
/// The card then says "Not enough history".
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

/// The simple baseline to compare against: the next purchase will cost
/// the same as the most recent one.
///
/// Returns null when there are no earlier purchases.
int? lastPriceBaseline(List<Purchase> purchases, DateTime before) {
  final lastThree = lastThreePurchases(purchases, before);
  if (lastThree.isEmpty) {
    return null;
  }
  return lastThree[0].actualPriceMinor;
}

/// The alternative from the proposal: the middle value of the last three
/// purchases. One very high price does not pull it up.
///
/// Returns null when there are fewer than three earlier purchases.
int? medianOfLastThree(List<Purchase> purchases, DateTime before) {
  final lastThree = lastThreePurchases(purchases, before);
  if (lastThree.length < 3) {
    return null;
  }

  final prices = [
    lastThree[0].actualPriceMinor,
    lastThree[1].actualPriceMinor,
    lastThree[2].actualPriceMinor,
  ];
  prices.sort();
  return prices[1];
}
