import 'package:flutter/material.dart';

import '../models/purchase.dart';
import '../utils/dates.dart';
import '../utils/lunch_lens.dart';
import '../utils/money.dart';

// Shows the Lunch Lens guess. It never fills in the price the user types.
class LunchLensCard extends StatelessWidget {
  final List<Purchase> purchases;

  const LunchLensCard({super.key, required this.purchases});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The next purchase happens now, so every purchase so far is earlier.
    final now = DateTime.now();
    final lastThree = lastThreePurchases(purchases, now);
    final estimate = averageOfLastThree(purchases, now);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Lunch Lens', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (estimate == null)
              _buildNotEnoughHistory(theme, lastThree.length)
            else
              _buildEstimate(theme, estimate, lastThree),
          ],
        ),
      ),
    );
  }

  Widget _buildNotEnoughHistory(ThemeData theme, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Not enough history', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Lunch Lens needs 3 purchases of this meal to make a guess. '
          'You have $count so far.',
        ),
      ],
    );
  }

  Widget _buildEstimate(
    ThemeData theme,
    int estimate,
    List<Purchase> lastThree,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Likely cost of your next purchase'),
        Text(
          formatMinor(estimate),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Moving average of your last three purchases:'),
        const SizedBox(height: 4),
        for (final purchase in lastThree)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(child: Text(formatDate(purchase.purchasedAt))),
                Text(formatMinor(purchase.actualPriceMinor)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'This is a simple rule (an average), not a trained model. '
          'One unusual price can pull it up or down.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
