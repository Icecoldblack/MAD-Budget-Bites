import 'package:flutter/material.dart';

import '../data/sample_meals.dart';
import '../models/meal.dart';
import '../widgets/empty_state.dart';
import '../widgets/meal_card.dart';
import 'meal_detail_screen.dart';
import 'meal_editor_screen.dart';

/// Screen 1: list of meals, cuisine filter, and budget left.
class CatalogScreen extends StatefulWidget {
  final List<Meal> meals;

  const CatalogScreen({super.key, this.meals = sampleMeals});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  /// Null means "All" cuisines.
  String? _selectedCuisine;

  List<String> get _cuisines {
    final cuisines = widget.meals.map((meal) => meal.cuisine).toSet().toList();
    cuisines.sort();
    return cuisines;
  }

  List<Meal> get _filteredMeals {
    if (_selectedCuisine == null) return widget.meals;
    return widget.meals
        .where((meal) => meal.cuisine == _selectedCuisine)
        .toList();
  }

  void _openEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MealEditorScreen()),
    );
  }

  void _openDetail(Meal meal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)),
    );
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
      body: widget.meals.isEmpty
          ? EmptyState(
              icon: Icons.restaurant_menu,
              title: 'No meals yet',
              message: 'Add a meal you buy often to start planning lunch.',
              actionLabel: 'Add a meal',
              onAction: _openEditor,
            )
          : Column(
              children: [
                _buildCuisineFilter(),
                Expanded(child: _buildMealList()),
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
