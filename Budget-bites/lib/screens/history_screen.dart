import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

/// Screen 4: date range, total spent, and the purchase list.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Purchases come from the PurchaseLog table once the database is added.
    // Until then there are none, so the empty state always shows.
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const EmptyState(
        icon: Icons.receipt_long,
        title: 'No purchases yet',
        message: 'Log a purchase from a meal\'s detail screen and it will '
            'show up here with your total spending.',
      ),
    );
  }
}
