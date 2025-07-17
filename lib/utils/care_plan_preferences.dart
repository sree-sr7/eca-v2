import 'package:shared_preferences/shared_preferences.dart';

class CarePlanPreferences {
  static const String _keySelectedCarePlan = 'selected_careplan_';

  // Save selected care plan for a user
  static Future<void> saveSelectedCarePlan(int userId, int carePlanId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keySelectedCarePlan$userId', carePlanId);
  }

  // Get selected care plan for a user
  static Future<int?> getSelectedCarePlan(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keySelectedCarePlan$userId');
  }

  // Clear selected care plan for a user
  static Future<void> clearSelectedCarePlan(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keySelectedCarePlan$userId');
  }
}