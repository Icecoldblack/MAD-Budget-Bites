import 'package:flutter/material.dart';

import '../data/meal_repository.dart';
import '../data/purchase_repository.dart';
import '../models/meal.dart';
import '../widgets/empty_state.dart';
import '../widgets/meal_card.dart';
import 'meal_detail_screen.dart';
import 'meal_editor_screen.dart';

/// Screen 1: list of meals, cuisine filter, and budget left.
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
  bool _isLoading = true;
  String? _errorMessage;

  /// Null means "All" cuisines.
  String? _selectedCuisine;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    try {
      final meals = await widget.mealRepository.getAllMeals();
      if (!mounted) return;
      setState(() {
        _meals = meals;
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

  List<String> get _cuisines {
    final cuisines = _meals.map((meal) => meal.cuisine).toSet().toList();
    cuisines.sort();
    return cuisines;
  }

  List<Meal> get _filteredMeals {
    if (_selectedCuisine == null) return _meals;
    return _meals.where((meal) => meal.cuisine == _selectedCuisine).toList();
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealEditorScreen(mealRepository: widget.mealRepository),
      ),
    );
    // Reload in case a meal was added.
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
    // Reload in case the meal was edited or deleted.
    _loadMeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meals')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        tooltip: 'Add meal',
        child: const Icon(Icons.add),
      ),
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

    if (_meals.isEmpty) {
      return EmptyState(
        icon: Icons.restaurant_menu,
        title: 'No meals yet',
        message: 'Add a meal you buy often to start planning lunch.',
        actionLabel: 'Add a meal',
        onAction: _openEditor,
      );
    }

    return Column(
      children: [
        _buildCuisineFilter(),
        Expanded(child: _buildMealList()),
      ],
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
            onSelected: (_) => setState(() => _selectedCuisine = null),
          ),
          for (final cuisine in _cuisines)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(cuisine),
                selected: _selectedCuisine == cuisine,
                onSelected: (_) => setState(() => _selectedCuisine = cuisine),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMealList() {
    final meals = _filteredMeals;

    // Happens when the last meal of the chosen cuisine is deleted.
    if (meals.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No meals match',
        message: 'No meals match the $_selectedCuisine filter.',
        actionLabel: 'Show all meals',
        onAction: () => setState(() => _selectedCuisine = null),
      );
    }

    return ListView.builder(
      // Bottom padding keeps the last card clear of the add button.
      padding: const EdgeInsets.only(top: 4, bottom: 88),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return MealCard(meal: meal, onTap: () => _openDetail(meal));
      },
    );
  }
}
