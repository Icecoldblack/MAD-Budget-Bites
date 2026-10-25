import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String dailyBudgetKey = 'dailyBudgetMinor';
  static const int defaultDailyBudgetMinor = 1000;

  Future<int> getDailyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(dailyBudgetKey) ?? defaultDailyBudgetMinor;
  }

  Future<void> setDailyBudget(int budgetMinor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(dailyBudgetKey, budgetMinor);
  }
}
