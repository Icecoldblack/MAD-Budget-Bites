import 'package:flutter/material.dart';

import '../models/purchase.dart';
import '../utils/dates.dart';
import '../utils/money.dart';

/// One row in a list of purchases. Tap it to edit, or tap the bin to delete.
/// Used on the detail screen and the history screen.
class PurchaseTile extends StatelessWidget {
  final Purchase purchase;

  /// The main text, e.g. the meal name on the history screen.
  final String title;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PurchaseTile({
    super.key,
    required this.purchase,
    required this.title,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    var subtitle = formatDate(purchase.purchasedAt);
    if (purchase.note.isNotEmpty) {
      subtitle = '$subtitle  •  ${purchase.note}';
    }

    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatMinor(purchase.actualPriceMinor),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete purchase',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
