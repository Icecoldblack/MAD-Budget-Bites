import 'package:flutter/material.dart';

import '../models/purchase.dart';
import '../utils/money.dart';

/// Compares the plan with what was really paid:
///   Plan        9.50
///   Actual      9.75
///   Difference +0.25 over plan
class ReceiptCard extends StatelessWidget {
  /// The meal's estimated price when it was planned.
  final int plannedPriceMinor;

  /// The purchase logged for this plan, or null if not bought yet.
  final Purchase? purchase;

  const ReceiptCard({
    super.key,
    required this.plannedPriceMinor,
    required this.purchase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Receipt', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _buildRow('Plan', formatMinor(plannedPriceMinor)),
            _buildRow(
              'Actual',
              purchase == null
                  ? 'Not bought yet'
                  : formatMinor(purchase!.actualPriceMinor),
            ),
            const Divider(),
            _buildDifference(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildDifference(ThemeData theme) {
    if (purchase == null) {
      return _buildRow('Difference', '-');
    }

    // Positive means the meal cost more than planned.
    final difference = purchase!.actualPriceMinor - plannedPriceMinor;

    String text;
    Color color;
    if (difference > 0) {
      text = '+${formatMinor(difference)} over plan';
      color = theme.colorScheme.error;
    } else if (difference < 0) {
      text = '${formatMinor(-difference)} under plan';
      color = Colors.green.shade700;
    } else {
      text = 'Exactly on plan';
      color = theme.colorScheme.primary;
    }

    return Row(
      children: [
        const Expanded(child: Text('Difference')),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
