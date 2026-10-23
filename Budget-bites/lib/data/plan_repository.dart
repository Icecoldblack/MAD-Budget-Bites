import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the current lunch plan with SharedPreferences.
/// A plan is just "which meal" and "when the plan was started".
class PlanRepository {
  static const String mealIdKey = 'planMealId';
  static const String startedAtKey = 'planStartedAt';

  /// The id of the planned meal, or null if there is no plan.
  Future<int?> getPlannedMealId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(mealIdKey);
  }

  /// When the plan was started, or null if there is no plan.
  Future<DateTime?> getPlanStartedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(startedAtKey);
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Starts a new plan for a meal. This replaces any old plan.
  Future<void> startPlan(int mealId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(mealIdKey, mealId);
    await prefs.setInt(startedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Removes the plan.
  Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(mealIdKey);
    await prefs.remove(startedAtKey);
  }
}
