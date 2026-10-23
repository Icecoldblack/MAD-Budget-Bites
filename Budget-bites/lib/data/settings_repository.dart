import 'package:shared_preferences/shared_preferences.dart';

/// Saves simple settings on the device with SharedPreferences.
class SettingsRepository {
  static const String dailyBudgetKey = 'dailyBudgetMinor';

  /// Used until the user picks a budget: 10.00.
  static const int defaultDailyBudgetMinor = 1000;

  /// The daily lunch budget in minor units.
  Future<int> getDailyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(dailyBudgetKey) ?? defaultDailyBudgetMinor;
  }

  Future<void> setDailyBudget(int budgetMinor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(dailyBudgetKey, budgetMinor);
  }
}
