import 'package:flutter/material.dart';

import '../data/meal_repository.dart';
import '../data/purchase_repository.dart';
import '../data/settings_repository.dart';
import '../models/meal.dart';
import '../utils/money.dart';
import '../widgets/empty_state.dart';
import '../widgets/meal_card.dart';
import 'meal_detail_screen.dart';
import 'meal_editor_screen.dart';

// Screen 1: list of meals, cuisine filter, and budget left today.
class CatalogScreen extends StatefulWidget {
  final MealRepository mealRepository;
  final PurchaseRepository purchaseRepository;

  const CatalogScreen({
    super.key,
    required this.mealRepository,
    required this.purchaseRepository,
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Meal> _meals = [];
  List<String> _cuisines = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Null means "All".
  String? _selectedCuisine;

  int _dailyBudgetMinor = 0;
  int _spentTodayMinor = 0;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    try {
      final cuisines = await widget.mealRepository.getCuisines();

      final budget = await SettingsRepository().getDailyBudget();
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);
      final spentToday = await widget.purchaseRepository.getTotalSpentInRange(
        startOfToday,
        startOfTomorrow,
      );

      List<Meal> meals;
      if (_selectedCuisine == null) {
        meals = await widget.mealRepository.getAllMeals();
      } else {
        meals = await widget.mealRepository.getMealsByCuisine(
          _selectedCuisine!,
        );
      }

      if (!mounted) return;
      setState(() {
        _cuisines = cuisines;
        _meals = meals;
        _dailyBudgetMinor = budget;
        _spentTodayMinor = spentToday;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load meals.';
      });
    }
  }

  void _selectCuisine(String? cuisine) {
    setState(() => _selectedCuisine = cuisine);
    _loadMeals();
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealEditorScreen(mealRepository: widget.mealRepository),
      ),
    );
    _loadMeals();
  }

  Future<void> _openDetail(Meal meal) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealDetailScreen(
          mealRepository: widget.mealRepository,
          purchaseRepository: widget.purchaseRepository,
          meal: meal,
        ),
      ),
    );
    _loadMeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meals')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: _errorMessage!,
        actionLabel: 'Try again',
        onAction: _loadMeals,
      );
    }

    if (_selectedCuisine == null && _meals.isEmpty) {
      return EmptyState(
        icon: Icons.restaurant_menu,
        title: 'No meals yet',
        message: 'Add a meal you buy often to start planning lunch.',
        actionLabel: 'Add a meal',
        onAction: _openEditor,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBudgetLeft(),
        _buildCuisineFilter(),
        Expanded(child: _buildMealList()),
      ],
    );
  }

  Widget _buildBudgetLeft() {
    final theme = Theme.of(context);
    final leftMinor = _dailyBudgetMinor - _spentTodayMinor;

    Color color = theme.colorScheme.primary;
    if (leftMinor < 0) {
      color = theme.colorScheme.error;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: color),
              const SizedBox(width: 8),
              Text(
                'Budget left today: ${formatMinor(leftMinor)} '
                'of ${formatMinor(_dailyBudgetMinor)}',
                style: theme.textTheme.titleSmall?.copyWith(color: color),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              'Set your daily budget in Settings',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuisineFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _selectedCuisine == null,
            onSelected: (_) => _selectCuisine(null),
          ),
          for (final cuisine in _cuisines)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(cuisine),
                selected: _selectedCuisine == cuisine,
                onSelected: (_) => _selectCuisine(cuisine),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMealList() {
    // Happens when the last meal of the chosen cuisine is deleted.
    if (_meals.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No meals match',
        message: 'No meals match the $_selectedCuisine filter.',
        actionLabel: 'Show all meals',
        onAction: () => _selectCuisine(null),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: _meals.length,
      itemBuilder: (context, index) {
        final meal = _meals[index];
        return MealCard(meal: meal, onTap: () => _openDetail(meal));
      },
    );
  }
}
