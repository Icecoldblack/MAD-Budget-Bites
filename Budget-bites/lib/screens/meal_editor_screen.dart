import 'package:flutter/material.dart';

import '../data/meal_repository.dart';
import '../models/meal.dart';
import '../utils/money.dart';

// Screen 2: one form to add a new meal or edit an existing one.
class MealEditorScreen extends StatefulWidget {
  final MealRepository mealRepository;

  // Null when adding a new meal.
  final Meal? meal;

  const MealEditorScreen({super.key, required this.mealRepository, this.meal});

  @override
  State<MealEditorScreen> createState() => _MealEditorScreenState();
}

class _MealEditorScreenState extends State<MealEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    if (meal != null) {
      _nameController.text = meal.name;
      _venueController.text = meal.venueNote;
      _cuisineController.text = meal.cuisine;
      _priceController.text = formatMinor(meal.estimatedPriceMinor);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _cuisineController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final meal = Meal(
      id: widget.meal?.id,
      name: _nameController.text.trim(),
      venueNote: _venueController.text.trim(),
      cuisine: _cuisineController.text.trim(),
      estimatedPriceMinor: parseMinor(_priceController.text)!,
    );

    try {
      if (widget.meal == null) {
        await widget.mealRepository.insertMeal(meal);
      } else {
        await widget.mealRepository.updateMeal(meal);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the meal. Try again.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (Navigator.of(context).canPop()) {
      // Opened from another screen: go back with the saved meal.
      Navigator.of(context).pop(meal);
    } else {
      // Opened from the Add tab: clear the form for the next meal.
      _nameController.clear();
      _venueController.clear();
      _cuisineController.clear();
      _priceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${meal.name} saved.')),
      );
    }
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a price.';
    }
    if (parseMinor(value) == null) {
      return 'Enter a price like 6.50';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.meal != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Meal' : 'Add Meal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Meal name'),
              validator: _validateRequired,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _venueController,
              decoration: const InputDecoration(
                labelText: 'Where to buy it (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cuisineController,
              decoration: const InputDecoration(labelText: 'Cuisine'),
              validator: _validateRequired,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Estimated price',
                hintText: '6.50',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validatePrice,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isSaving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
