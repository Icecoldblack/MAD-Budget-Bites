import 'package:flutter/material.dart';

import '../data/meal_repository.dart';
import '../data/purchase_repository.dart';
import 'catalog_screen.dart';
import 'history_screen.dart';
import 'meal_detail_screen.dart';
import 'meal_editor_screen.dart';
import 'settings_screen.dart';

/// Holds the bottom tab bar and switches between the five main screens.
class HomeShell extends StatefulWidget {
  final MealRepository mealRepository;
  final PurchaseRepository purchaseRepository;

  const HomeShell({
    super.key,
    required this.mealRepository,
    required this.purchaseRepository,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // A screen is rebuilt each time its tab is opened, so it always
    // loads the latest data from the database.
    final screens = [
      CatalogScreen(
        mealRepository: widget.mealRepository,
        purchaseRepository: widget.purchaseRepository,
      ),
      MealEditorScreen(mealRepository: widget.mealRepository),
      MealDetailScreen(
        mealRepository: widget.mealRepository,
        purchaseRepository: widget.purchaseRepository,
      ),
      HistoryScreen(
        mealRepository: widget.mealRepository,
        purchaseRepository: widget.purchaseRepository,
      ),
      SettingsScreen(
        mealRepository: widget.mealRepository,
        purchaseRepository: widget.purchaseRepository,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Meals',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
