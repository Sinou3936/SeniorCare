import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter/services.dart';
import '../models/medicine.dart';
import '../models/appointment.dart';
import 'firestore_service.dart';
import 'prefs_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'medicine_reminders';
  static const _channelName = '복약 알림';
  static const _alarmChannelId = 'medicine_alarms';
  static const _alarmChannelName = '복약 알람';

  // 일반 알림 (병원, 테스트, FCM 포그라운드)
  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  // 복약 슬롯 알람 전용 — FLAG_INSISTENT(탭 전 소리 루프)
  static final _alarmNotificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      importance: Importance.max,
      priority: Priority.max,
      additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT
    ),
  );

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (_) {},
    );

    // 일반 알림 채널
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
          enableVibration: true,
        ));

    // 복약 알람 채널 (최대 중요도, fullScreenIntent용)
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _alarmChannelId,
          _alarmChannelName,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ));

    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
    await _requestBatteryOptimizationExemption();

    FirebaseMessaging.onMessage.listen(_showLocal);

    final token = await _messaging.getToken();
    if (token != null) await FirestoreService.saveFcmToken(token);
    _messaging.onTokenRefresh.listen(FirestoreService.saveFcmToken);
  }

  // ── 슬롯 단위 알람 ────────────────────────────────────────

  /// 슬롯 알람 ID: "08:00" → 50480
  static int _slotNotificationId(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return 50000 + hour * 60 + minute;
  }

  /// 전체 활성 약을 슬롯 단위로 재등록 + 캐시 갱신 (메인 진입점)
  static Future<void> rescheduleAllAlarms(List<Medicine> medicines) async {
    // cancelAll로 구 방식 알람(per-medicine ID)까지 전부 제거
    await _local.cancelAll();
    await _scheduleSlotAlarms(medicines);
    await rebuildScheduleCache(medicines);
  }

  static Future<void> _scheduleSlotAlarms(List<Medicine> medicines) async {
    final Map<String, List<String>> timeToNames = {};
    for (final m in medicines) {
      for (final t in m.times) {
        timeToNames.putIfAbsent(t, () => []).add(m.name);
      }
    }

    for (final entry in timeToNames.entries) {
      final time = entry.key;
      final names = entry.value;
      final parts = time.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      await _local.zonedSchedule(
        id: _slotNotificationId(time),
        title: '복약 시간이에요 💊',
        body: names.join(', '),
        scheduledDate: _nextOccurrence(hour, minute),
        notificationDetails: _alarmNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: time,
      );
    }
  }

  /// 캐시 기반으로 등록된 슬롯 알람 전체 취소
  static Future<void> cancelAllSlotAlarms() async {
    final schedule = await PrefsService.loadMedicineSchedule();
    for (final time in schedule.keys) {
      await _local.cancel(id: _slotNotificationId(time));
    }
  }

  /// SharedPreferences 약 스케줄 캐시 갱신
  static Future<void> rebuildScheduleCache(List<Medicine> medicines) async {
    final Map<String, List<Map<String, String>>> schedule = {};
    for (final m in medicines) {
      for (final t in m.times) {
        schedule.putIfAbsent(t, () => []).add({'id': m.id, 'name': m.name});
      }
    }
    await PrefsService.saveMedicineSchedule(schedule);
  }

  /// 10분 후 다시 알림 (스누즈) — one-shot
  static Future<void> scheduleSnoozeAlarm({
    required String time,
    required List<String> medicineNames,
    required DateTime scheduledAt,
  }) async {
    final tzTime = tz.TZDateTime(
      tz.local,
      scheduledAt.year, scheduledAt.month, scheduledAt.day,
      scheduledAt.hour, scheduledAt.minute,
    );
    await _local.zonedSchedule(
      id: 60000 + _slotNotificationId(time),
      title: '복약 시간이에요 💊',
      body: medicineNames.join(', '),
      scheduledDate: tzTime,
      notificationDetails: _alarmNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: time,
    );
  }

  /// 약 삭제/토글 OFF용 — 하위 호환 유지, 슬롯 재등록으로 대체 권장
  static Future<void> cancelMedicineAlarms(String medicineId, {List<String>? times}) async {}

  // ── 병원 예약 알람 ────────────────────────────────────────

  static Future<void> scheduleAppointmentAlarm(Appointment appointment) async {
    final enabled = await PrefsService.loadHospitalNotificationEnabled();
    if (!enabled) return;
    final notifyTime = appointment.date.subtract(const Duration(hours: 2));
    final now = tz.TZDateTime.now(tz.local);
    final tzNotifyTime = tz.TZDateTime(
      tz.local,
      notifyTime.year, notifyTime.month, notifyTime.day,
      notifyTime.hour, notifyTime.minute,
    );
    if (tzNotifyTime.isBefore(now)) return;

    await _local.zonedSchedule(
      id: _appointmentNotificationId(appointment.id),
      title: '병원 예약 알림',
      body: '${appointment.hospitalName} 예약이 2시간 후에 있어요!',
      scheduledDate: tzNotifyTime,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  static Future<void> rescheduleAppointmentAlarms(List<Appointment> appointments) async {
    for (final a in appointments) {
      await scheduleAppointmentAlarm(a);
    }
  }

  static Future<void> cancelAppointmentAlarm(String appointmentId) async {
    await _local.cancel(id: _appointmentNotificationId(appointmentId));
  }

  static int _appointmentNotificationId(String appointmentId) {
    return 20000000 + (appointmentId.hashCode.abs() % 1000000);
  }

  // ── 기타 ─────────────────────────────────────────────────

  // ignore: invalid_use_of_visible_for_testing_member
  static int notificationIdForTest(String medicineId, int timeIndex) =>
      _slotNotificationId('08:00');

  // ignore: invalid_use_of_visible_for_testing_member
  static int slotNotificationIdForTest(String time) => _slotNotificationId(time);

  static Future<void> sendTestNotification() async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    await _local.zonedSchedule(
      id: 99999,
      title: '알림 테스트',
      body: '예약 알림이 정상 동작합니다!',
      scheduledDate: scheduledTime,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  static Future<bool> canScheduleExact() async {
    return await Permission.scheduleExactAlarm.isGranted;
  }

  static Future<void> openExactAlarmSettings() async {
    await Permission.scheduleExactAlarm.request();
  }

  static tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> _requestBatteryOptimizationExemption() async {
    try {
      const channel = MethodChannel('yakbom/battery');
      await channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }

  static Future<void> _showLocal(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    final enabled = await PrefsService.loadNotificationEnabled();
    if (!enabled) return;
    await _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: _notificationDetails,
    );
  }
}
