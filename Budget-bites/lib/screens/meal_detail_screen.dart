import 'package:flutter/material.dart';

import '../data/meal_repository.dart';
import '../models/meal.dart';
import '../widgets/meal_card.dart';
import 'meal_editor_screen.dart';

/// Screen 3: meal detail, receipt card, Lunch Lens, and the plan flow.
class MealDetailScreen extends StatefulWidget {
  final MealRepository mealRepository;

  /// The meal being viewed. Null when opened from the Plan tab with no plan.
  final Meal? meal;

  const MealDetailScreen({super.key, required this.mealRepository, this.meal});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  Meal? _meal;

  @override
  void initState() {
    super.initState();
    _meal = widget.meal;
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete meal?'),
        content: Text('${meal.name} will be deleted. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await widget.mealRepository.deleteMeal(meal.id!);
    if (!mounted) return;
    Navigator.of(context).pop();
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
        ],
      ),
    );
  }
}
