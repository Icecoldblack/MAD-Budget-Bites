import 'package:flutter/material.dart';

import '../data/meal_repository.dart';
import '../data/purchase_repository.dart';
import '../models/meal.dart';
import '../models/purchase.dart';
import '../utils/dates.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/lunch_lens_card.dart';
import '../widgets/meal_card.dart';
import '../widgets/purchase_dialog.dart';
import '../widgets/purchase_tile.dart';
import 'meal_editor_screen.dart';

/// Screen 3: meal detail, receipt card, Lunch Lens, and the plan flow.
class MealDetailScreen extends StatefulWidget {
  final MealRepository mealRepository;
  final PurchaseRepository purchaseRepository;

  /// The meal being viewed. Null when opened from the Plan tab with no plan.
  final Meal? meal;

  const MealDetailScreen({
    super.key,
    required this.mealRepository,
    required this.purchaseRepository,
    this.meal,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  Meal? _meal;
  List<Purchase> _purchases = [];

  @override
  void initState() {
    super.initState();
    _meal = widget.meal;
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    final meal = _meal;
    if (meal == null) return;

    final purchases =
        await widget.purchaseRepository.getPurchasesForMeal(meal.id!);
    if (!mounted) return;
    setState(() => _purchases = purchases);
  }

  Future<void> _editMeal() async {
    final updatedMeal = await Navigator.of(context).push<Meal>(
      MaterialPageRoute(
        builder: (_) => MealEditorScreen(
          mealRepository: widget.mealRepository,
          meal: _meal,
        ),
      ),
    );

    // The editor hands back the saved meal, or null if the user went back.
    if (updatedMeal != null) {
      setState(() => _meal = updatedMeal);
    }
  }

  Future<void> _deleteMeal() async {
    final meal = _meal!;

    // Tell the user how many purchases will be deleted with the meal.
    final count =
        await widget.purchaseRepository.countPurchasesForMeal(meal.id!);
    if (!mounted) return;

    var message = '${meal.name} will be deleted.';
    if (count == 1) {
      message = '$message Its 1 purchase will also be deleted.';
    } else if (count > 1) {
      message = '$message Its $count purchases will also be deleted.';
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete meal?',
      message: '$message This cannot be undone.',
    );
    if (!confirmed) return;

    await widget.mealRepository.deleteMeal(meal.id!);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Opens the purchase form. Pass a purchase to edit it, or null to log
  /// a new one.
  Future<void> _openPurchaseDialog(Purchase? purchase) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => PurchaseDialog(
        purchaseRepository: widget.purchaseRepository,
        mealId: _meal!.id!,
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
    final meal = _meal;

    if (meal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plan')),
        body: const Center(child: Text('Meal detail and plan')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(meal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit meal',
            onPressed: _editMeal,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete meal',
            onPressed: _deleteMeal,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          MealCard(meal: meal),
          LunchLensCard(purchases: _purchases),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => _openPurchaseDialog(null),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Log purchase'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Purchases',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_purchases.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No purchases of this meal yet.'),
            ),
          for (final purchase in _purchases)
            PurchaseTile(
              purchase: purchase,
              title: formatDate(purchase.purchasedAt),
              onTap: () => _openPurchaseDialog(purchase),
              onDelete: () => _deletePurchase(purchase),
            ),
        ],
      ),
    );
  }
}
