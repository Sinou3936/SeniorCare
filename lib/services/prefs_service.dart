import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _keyMode = 'app_mode';
  static const _keyNotification = 'notification_enabled';

  static Future<void> saveMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMode, mode);
  }

  static Future<String?> loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMode);
  }

  static Future<void> clearMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMode);
  }

  static Future<void> saveNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotification, enabled);
  }

  static Future<bool> loadNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotification) ?? true;
  }
}
