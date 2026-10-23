import 'package:flutter/material.dart';

import '../data/meal_repository.dart';
import '../data/purchase_repository.dart';
import '../data/sample_data.dart';
import '../data/settings_repository.dart';
import '../utils/money.dart';
import '../widgets/confirm_dialog.dart';

/// Screen 5: daily budget slider and display option.
class SettingsScreen extends StatefulWidget {
  final MealRepository mealRepository;
  final PurchaseRepository purchaseRepository;

  const SettingsScreen({
    super.key,
    required this.mealRepository,
    required this.purchaseRepository,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// The slider goes from 0.00 to 30.00 in steps of 0.50.
  static const int maxBudgetMinor = 3000;
  static const int stepMinor = 50;

  final _settings = SettingsRepository();
  int _dailyBudgetMinor = SettingsRepository.defaultDailyBudgetMinor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final budget = await _settings.getDailyBudget();
    if (!mounted) return;
    setState(() {
      _dailyBudgetMinor = budget;
      _isLoading = false;
    });
  }

  Future<void> _loadSampleData() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Load sample data?',
      message: 'This adds 6 sample meals and 10 purchases so you can try '
          'the app. Your own meals are kept. Each tap adds another copy.',
      confirmLabel: 'Load',
    );
    if (!confirmed) return;

    await addSampleData(widget.mealRepository, widget.purchaseRepository);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sample data added.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Daily lunch budget', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          // The number is shown in text, not only by the slider position.
          Text(
            formatMinor(_dailyBudgetMinor),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _dailyBudgetMinor.toDouble(),
            min: 0,
            max: maxBudgetMinor.toDouble(),
            divisions: maxBudgetMinor ~/ stepMinor,
            label: formatMinor(_dailyBudgetMinor),
            // Update the number while dragging...
            onChanged: (value) {
              setState(() => _dailyBudgetMinor = value.round());
            },
            // ...and save only when the user lets go.
            onChangeEnd: (value) {
              _settings.setDailyBudget(value.round());
            },
          ),
          Text(
            'Used on the Meals screen to show how much of today\'s budget '
            'is left.',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 48),
          Text('Testing', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadSampleData,
            icon: const Icon(Icons.science_outlined),
            label: const Text('Load sample data'),
          ),
        ],
      ),
    );
  }
}
