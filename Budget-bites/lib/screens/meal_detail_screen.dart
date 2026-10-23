import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../widgets/meal_card.dart';

/// Screen 3: meal detail, receipt card, Lunch Lens, and the plan flow.
class MealDetailScreen extends StatelessWidget {
  /// The meal being viewed. Null when opened from the Plan tab with no plan.
  final Meal? meal;

  const MealDetailScreen({super.key, this.meal});

  @override
  Widget build(BuildContext context) {
    final meal = this.meal;

    return Scaffold(
      appBar: AppBar(title: Text(meal?.name ?? 'Plan')),
      body: meal == null
          ? const Center(child: Text('Meal detail and plan'))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                MealCard(meal: meal),
              ],
            ),
    );
  }
}
