import 'package:flutter/material.dart';

/// Screen 3: meal detail, receipt card, Lunch Lens, and the plan flow.
class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: const Center(child: Text('Meal detail and plan')),
    );
  }
}
