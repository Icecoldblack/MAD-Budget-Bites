import 'package:shared_preferences/shared_preferences.dart';

// The lunch plan is saved with SharedPreferences: which meal, when it
// started, and whether it is finished.
class PlanRepository {
  static const String mealIdKey = 'planMealId';
  static const String startedAtKey = 'planStartedAt';
  static const String finishedKey = 'planFinished';

  Future<int?> getPlannedMealId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(mealIdKey);
  }

  Future<DateTime?> getPlanStartedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(startedAtKey);
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<bool> isPlanFinished() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(finishedKey) ?? false;
  }

  // Replaces any old plan. The sample data passes [startedAt]; normally
  // the plan starts now.
  Future<void> startPlan(int mealId, {DateTime? startedAt}) async {
    final time = startedAt ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(mealIdKey, mealId);
    await prefs.setInt(startedAtKey, time.millisecondsSinceEpoch);
    await prefs.setBool(finishedKey, false);
  }

  Future<void> finishPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(finishedKey, true);
  }

  Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(mealIdKey);
    await prefs.remove(startedAtKey);
    await prefs.remove(finishedKey);
  }
}
