import 'package:flutter/material.dart';

/// Screen 1: list of meals, cuisine filter, and budget left.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meals')),
      body: const Center(child: Text('Meal catalog')),
    );
  }
}
