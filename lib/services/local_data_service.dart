import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adhan_scheduler_service.dart';

class LocalDataService {
  static Future<void> clearAll() async {
    // Cancel scheduled alarms before removing the IDs used to manage them.
    await AdhanSchedulerService.cancelScheduled();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
