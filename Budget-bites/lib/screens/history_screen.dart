import 'package:flutter/material.dart';

import '../data/meal_repository.dart';
import '../data/purchase_repository.dart';
import '../models/purchase.dart';
import '../utils/dates.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/purchase_dialog.dart';
import '../widgets/purchase_tile.dart';

/// Screen 4: date range, total spent, and the purchase list.
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

  /// Meal names by meal id, so each purchase can show its meal's name.
  Map<int, String> _mealNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    final purchases = await widget.purchaseRepository.getAllPurchases();
    final meals = await widget.mealRepository.getAllMeals();

    final mealNames = <int, String>{};
    for (final meal in meals) {
      mealNames[meal.id!] = meal.name;
    }

    if (!mounted) return;
    setState(() {
      _purchases = purchases;
      _mealNames = mealNames;
      _isLoading = false;
    });
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

    if (_purchases.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long,
        title: 'No purchases yet',
        message: 'Log a purchase from a meal\'s detail screen and it will '
            'show up here with your total spending.',
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
