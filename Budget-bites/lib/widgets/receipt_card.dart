import 'package:flutter/material.dart';

import '../models/purchase.dart';
import '../utils/money.dart';

// Compares the planned price with what was really paid.
class ReceiptCard extends StatelessWidget {
  final int plannedPriceMinor;

  // Null until the planned meal is bought.
  final Purchase? purchase;

  const ReceiptCard({
    super.key,
    required this.plannedPriceMinor,
    required this.purchase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String actualText = 'Not bought yet';
    if (purchase != null) {
      actualText = formatMinor(purchase!.actualPriceMinor);
    }

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
            _buildRow('Actual', actualText),
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

    // Positive means it cost more than planned.
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
