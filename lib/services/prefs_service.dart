import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _keyMode = 'app_mode';
  static const _keyNotification = 'notification_enabled';
  static const _keyHospitalNotification = 'hospital_notification_enabled';
  static const _keyLinkedSeniorUid = 'linked_senior_uid';
  static const _keyMedicineSchedule = 'medicine_schedule_cache';

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

  static Future<void> saveHospitalNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHospitalNotification, enabled);
  }

  static Future<bool> loadHospitalNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHospitalNotification) ?? true;
  }

  static Future<void> saveLinkedSeniorUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLinkedSeniorUid, uid);
  }

  static Future<String?> loadLinkedSeniorUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLinkedSeniorUid);
  }

  static Future<void> clearLinkedSeniorUid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLinkedSeniorUid);
  }

  // 슬롯 알람용 캐시: {"08:00": [{"id": "...", "name": "혈압약"}, ...], ...}
  static Future<void> saveMedicineSchedule(Map<String, List<Map<String, String>>> schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMedicineSchedule, jsonEncode(schedule));
  }

  static Future<Map<String, List<Map<String, String>>>> loadMedicineSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMedicineSchedule);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((time, meds) => MapEntry(
      time,
      (meds as List).map((m) => Map<String, String>.from(m as Map)).toList(),
    ));
  }
}
