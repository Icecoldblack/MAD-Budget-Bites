import 'package:flutter/material.dart';

import '../data/meal_repository.dart';
import '../data/plan_repository.dart';
import '../data/purchase_repository.dart';
import '../models/meal.dart';
import '../models/purchase.dart';
import '../utils/dates.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/lunch_lens_card.dart';
import '../widgets/meal_card.dart';
import '../widgets/plan_progress.dart';
import '../widgets/purchase_dialog.dart';
import '../widgets/purchase_tile.dart';
import '../widgets/receipt_card.dart';
import 'meal_editor_screen.dart';

// Screen 3: meal detail, plan, receipt, and Lunch Lens.
// From the Meals tab it gets a meal. From the Plan tab it gets no meal and
// shows the planned meal instead, or "No plan yet".
class MealDetailScreen extends StatefulWidget {
  final MealRepository mealRepository;
  final PurchaseRepository purchaseRepository;
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
  final _planRepository = PlanRepository();

  Meal? _meal;
  List<Purchase> _purchases = [];
  int? _plannedMealId;
  DateTime? _planStartedAt;
  bool _planFinished = false;
  bool _isLoading = true;

  bool get _isPlanTab => widget.meal == null;

  @override
  void initState() {
    super.initState();
    _meal = widget.meal;
    _load();
  }

  Future<void> _load() async {
    final plannedMealId = await _planRepository.getPlannedMealId();
    final planStartedAt = await _planRepository.getPlanStartedAt();
    final planFinished = await _planRepository.isPlanFinished();

    Meal? meal = _meal;
    if (_isPlanTab && plannedMealId != null) {
      meal = await widget.mealRepository.getMealById(plannedMealId);
    }

    List<Purchase> purchases = [];
    if (meal != null) {
      purchases = await widget.purchaseRepository.getPurchasesForMeal(
        meal.id!,
      );
    }

    if (!mounted) return;
    setState(() {
      _plannedMealId = plannedMealId;
      _planStartedAt = planStartedAt;
      _planFinished = planFinished;
      _meal = meal;
      _purchases = purchases;
      _isLoading = false;
    });
  }

  Future<void> _startPlan() async {
    final meal = _meal!;

    // Ask before replacing a plan that is not finished yet.
    if (_plannedMealId != null && _plannedMealId != meal.id && !_planFinished) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Replace your plan?',
        message: 'You already have a lunch plan. '
            'Planning ${meal.name} will replace it.',
        confirmLabel: 'Replace',
      );
      if (!confirmed) return;
    }

    await _planRepository.startPlan(meal.id!);
    final startedAt = await _planRepository.getPlanStartedAt();
    if (!mounted) return;
    setState(() {
      _plannedMealId = meal.id;
      _planStartedAt = startedAt;
      _planFinished = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${meal.name} is your lunch plan.')),
    );
  }

  Future<void> _finishPlan() async {
    await _planRepository.finishPlan();
    if (!mounted) return;
    setState(() => _planFinished = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan finished. Nice work!')),
    );
  }

  Future<void> _resetPlan() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset plan?',
      message: 'Your lunch plan will be removed. '
          'Your purchases are kept.',
      confirmLabel: 'Reset',
    );
    if (!confirmed) return;

    await _planRepository.clearPlan();
    if (!mounted) return;

    setState(() {
      _plannedMealId = null;
      _planStartedAt = null;
      _planFinished = false;
      if (_isPlanTab) {
        _meal = null;
        _purchases = [];
      }
    });
  }

  // The newest purchase made after the plan started, or null.
  // _purchases is newest first, so the first match is the newest.
  Purchase? _findPlanPurchase() {
    if (_planStartedAt == null) return null;

    for (final purchase in _purchases) {
      if (!purchase.purchasedAt.isBefore(_planStartedAt!)) {
        return purchase;
      }
    }
    return null;
  }

  Future<void> _editMeal() async {
    // The editor gives back the saved meal, or null if the user went back.
    final updatedMeal = await Navigator.of(context).push<Meal>(
      MaterialPageRoute(
        builder: (_) => MealEditorScreen(
          mealRepository: widget.mealRepository,
          meal: _meal,
        ),
      ),
    );

    if (updatedMeal != null) {
      setState(() => _meal = updatedMeal);
    }
  }

  Future<void> _deleteMeal() async {
    final meal = _meal!;

    final count =
        await widget.purchaseRepository.countPurchasesForMeal(meal.id!);
    if (!mounted) return;

    String message = '${meal.name} will be deleted.';
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
    if (_plannedMealId == meal.id) {
      await _planRepository.clearPlan();
    }
    if (!mounted) return;

    if (_isPlanTab) {
      // The Plan tab has nowhere to go back to, so show "No plan yet".
      setState(() {
        _meal = null;
        _purchases = [];
        _plannedMealId = null;
        _planStartedAt = null;
        _planFinished = false;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  // Pass null to log a new purchase, or a purchase to edit it.
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
      _load();
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
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_meal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plan')),
        body: const EmptyState(
          icon: Icons.event_note,
          title: 'No plan yet',
          message: 'Open a meal on the Meals tab and tap "Plan this meal".',
        ),
      );
    }

    final meal = _meal!;
    final isPlanned = _plannedMealId == meal.id;
    final planPurchase = _findPlanPurchase();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPlanTab ? 'Your plan' : meal.name),
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
          if (isPlanned) _buildPlanLabel() else _buildPlanButton(),
          if (isPlanned)
            PlanProgress(
              isBought: planPurchase != null,
              isFinished: _planFinished,
            ),
          if (isPlanned)
            ReceiptCard(
              plannedPriceMinor: meal.estimatedPriceMinor,
              purchase: planPurchase,
            ),
          if (isPlanned) _buildPlanActions(planPurchase != null),
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
              showDate: false,
              onTap: () => _openPurchaseDialog(purchase),
              onDelete: () => _deletePurchase(purchase),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: _startPlan,
        icon: const Icon(Icons.event_available),
        label: const Text('Plan this meal'),
      ),
    );
  }

  Widget _buildPlanLabel() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            _planFinished ? 'Plan finished' : 'This is your lunch plan',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanActions(bool isBought) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (!_planFinished)
                Expanded(
                  child: FilledButton.icon(
                    // Off until the planned meal is bought.
                    onPressed: isBought ? _finishPlan : null,
                    icon: const Icon(Icons.flag),
                    label: const Text('Finish plan'),
                  ),
                ),
              if (!_planFinished) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetPlan,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset plan'),
                ),
              ),
            ],
          ),
          if (!isBought && !_planFinished)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Log a purchase of this meal to finish the plan.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
