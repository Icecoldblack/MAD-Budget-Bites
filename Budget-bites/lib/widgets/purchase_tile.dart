import 'package:flutter/material.dart';

import '../models/purchase.dart';
import '../utils/dates.dart';
import '../utils/money.dart';

class PurchaseTile extends StatelessWidget {
  final Purchase purchase;
  final String title;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  // Turn off when the title already is the date (on the detail screen).
  final bool showDate;

  const PurchaseTile({
    super.key,
    required this.purchase,
    required this.title,
    required this.onTap,
    required this.onDelete,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    String subtitle = '';
    if (showDate) {
      subtitle = formatDate(purchase.purchasedAt);
    }
    if (purchase.note.isNotEmpty) {
      if (subtitle.isEmpty) {
        subtitle = purchase.note;
      } else {
        subtitle = '$subtitle  •  ${purchase.note}';
      }
    }

    return ListTile(
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
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
