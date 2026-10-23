import 'package:flutter/material.dart';

import '../data/sample_meals.dart';
import '../widgets/meal_card.dart';
import 'meal_detail_screen.dart';

/// Screen 1: list of meals, cuisine filter, and budget left.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const meals = sampleMeals;

    return Scaffold(
      appBar: AppBar(title: const Text('Meals')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: meals.length,
        itemBuilder: (context, index) {
          final meal = meals[index];
          return MealCard(
            meal: meal,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MealDetailScreen(meal: meal),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
