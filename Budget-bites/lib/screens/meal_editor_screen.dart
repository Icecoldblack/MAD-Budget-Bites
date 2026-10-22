import 'package:flutter/material.dart';

/// Screen 2: one form for creating a new meal or editing an existing one.
class MealEditorScreen extends StatelessWidget {
  const MealEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Meal')),
      body: const Center(child: Text('Meal form')),
    );
  }
}
