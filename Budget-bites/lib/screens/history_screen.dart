import 'package:flutter/material.dart';

import '../data/meal_repository.dart';
import '../data/purchase_repository.dart';
import '../models/purchase.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/purchase_dialog.dart';
import '../widgets/purchase_tile.dart';

// Screen 4: date range, total spent, and the purchase list.
class HistoryScreen extends StatefulWidget {
  final MealRepository mealRepository;
  final PurchaseRepository purchaseRepository;

  const HistoryScreen({
    super.key,
    required this.mealRepository,
    required this.purchaseRepository,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Purchase> _purchases = [];
  int _totalSpentMinor = 0;

  // Null means "All time".
  DateTimeRange? _range;

  // Meal name for each meal id.
  Map<int, String> _mealNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    List<Purchase> purchases;
    int total;

    if (_range == null) {
      purchases = await widget.purchaseRepository.getAllPurchases();
      total = await widget.purchaseRepository.getTotalSpent();
    } else {
      // The picker gives the last day at midnight. Add a day so purchases
      // made during the last day count too.
      final from = _range!.start;
      final end = _range!.end;
      final to = DateTime(end.year, end.month, end.day + 1);
      purchases = await widget.purchaseRepository.getPurchasesInRange(from, to);
      total = await widget.purchaseRepository.getTotalSpentInRange(from, to);
    }

    final meals = await widget.mealRepository.getAllMeals();
    Map<int, String> mealNames = {};
    for (final meal in meals) {
      mealNames[meal.id!] = meal.name;
    }

    if (!mounted) return;
    setState(() {
      _purchases = purchases;
      _totalSpentMinor = total;
      _mealNames = mealNames;
      _isLoading = false;
    });
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked == null) return;

    setState(() => _range = picked);
    _loadPurchases();
  }

  void _showAllTime() {
    setState(() => _range = null);
    _loadPurchases();
  }

  Future<void> _editPurchase(Purchase purchase) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => PurchaseDialog(
        purchaseRepository: widget.purchaseRepository,
        mealId: purchase.mealId,
        purchase: purchase,
      ),
    );
    if (saved == true) {
      _loadPurchases();
    }
  }

  Future<void> _deletePurchase(Purchase purchase) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete purchase?',
      message: 'The purchase from ${formatDate(purchase.purchasedAt)} '
          'will be deleted. This cannot be undone.',
    );
    if (!confirmed) return;

    await widget.purchaseRepository.deletePurchase(purchase.id!);
    _loadPurchases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_range == null && _purchases.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long,
        title: 'No purchases yet',
        message: 'Log a purchase from a meal\'s detail screen and it will '
            'show up here with your total spending.',
      );
    }

    return Column(
      children: [
        _buildTotalCard(),
        Expanded(child: _buildPurchaseList()),
      ],
    );
  }

  Widget _buildTotalCard() {
    final theme = Theme.of(context);

    String periodText = 'All time';
    if (_range != null) {
      periodText =
          '${formatDate(_range!.start)} to ${formatDate(_range!.end)}';
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total spent', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              formatMinor(_totalSpentMinor),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(periodText)),
                TextButton(
                  onPressed: _pickRange,
                  child: const Text('Change dates'),
                ),
                if (_range != null)
                  TextButton(
                    onPressed: _showAllTime,
                    child: const Text('All time'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseList() {
    if (_purchases.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy,
        title: 'No purchases in this period',
        message: 'Pick other dates, or show all time.',
        actionLabel: 'Show all time',
        onAction: _showAllTime,
      );
    }

    return ListView.builder(
      itemCount: _purchases.length,
      itemBuilder: (context, index) {
        final purchase = _purchases[index];
        return PurchaseTile(
          purchase: purchase,
          title: _mealNames[purchase.mealId] ?? 'Unknown meal',
          onTap: () => _editPurchase(purchase),
          onDelete: () => _deletePurchase(purchase),
        );
      },
    );
  }
}
