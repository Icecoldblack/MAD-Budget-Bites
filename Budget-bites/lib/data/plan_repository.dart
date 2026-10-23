import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the current lunch plan with SharedPreferences.
/// A plan is "which meal", "when the plan was started", and
/// "is it finished".
class PlanRepository {
  static const String mealIdKey = 'planMealId';
  static const String startedAtKey = 'planStartedAt';
  static const String finishedKey = 'planFinished';

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

  /// True if the user finished the plan.
  Future<bool> isPlanFinished() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(finishedKey) ?? false;
  }

  /// Starts a new plan for a meal. This replaces any old plan.
  /// The plan starts now, unless a [startedAt] time is given
  /// (the sample data uses this).
  Future<void> startPlan(int mealId, {DateTime? startedAt}) async {
    final time = startedAt ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(mealIdKey, mealId);
    await prefs.setInt(startedAtKey, time.millisecondsSinceEpoch);
    await prefs.setBool(finishedKey, false);
  }

  /// Marks the plan as finished. The plan stays so the receipt can
  /// still be seen.
  Future<void> finishPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(finishedKey, true);
  }

  /// Removes the plan (used by Reset).
  Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(mealIdKey);
    await prefs.remove(startedAtKey);
    await prefs.remove(finishedKey);
  }
}
