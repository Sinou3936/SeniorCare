import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'medicine_reminders';
  static const _channelName = '복약 알림';

  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _notificationDetails =
      NotificationDetails(android: _androidDetails);

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // timezone 초기화
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (_) {},
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      enableVibration: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 정확한 알람 권한 요청 (Android 12+)
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    FirebaseMessaging.onMessage.listen(_showLocal);

    final token = await _messaging.getToken();
    if (token != null) await FirestoreService.saveFcmToken(token);
    _messaging.onTokenRefresh.listen(FirestoreService.saveFcmToken);
  }

  /// 약 복용 알림 스케줄링 — 약 추가/수정 시 호출
  /// [medicineId] 기준으로 기존 알림 취소 후 재등록
  static Future<void> scheduleMedicineAlarms({
    required String medicineId,
    required String medicineName,
    required List<String> times, // "HH:mm" 형식
  }) async {
    await cancelMedicineAlarms(medicineId);

    for (int i = 0; i < times.length; i++) {
      final parts = times[i].split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final id = _notificationId(medicineId, i);
      final scheduledTime = _nextOccurrence(hour, minute);

      try {
        await _local.zonedSchedule(
          id: id,
          title: '복약 알림',
          body: '$medicineName 드실 시간이에요!',
          scheduledDate: scheduledTime,
          notificationDetails: _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        // 정확한 알람 권한 없을 때 inexact로 폴백
        await _local.zonedSchedule(
          id: id,
          title: '복약 알림',
          body: '$medicineName 드실 시간이에요!',
          scheduledDate: scheduledTime,
          notificationDetails: _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  /// 약 삭제 시 해당 약의 모든 알림 취소
  static Future<void> cancelMedicineAlarms(String medicineId) async {
    // 최대 시간대 수만큼 취소 시도 (아침/점심/저녁/취침 = 최대 4개)
    for (int i = 0; i < 10; i++) {
      await _local.cancel(id: _notificationId(medicineId, i));
    }
  }

  /// medicineId + 시간대 인덱스로 고유 알림 ID 생성
  static int _notificationId(String medicineId, int timeIndex) {
    return (medicineId.hashCode.abs() % 100000) * 10 + timeIndex;
  }

  // ignore: invalid_use_of_visible_for_testing_member
  static int notificationIdForTest(String medicineId, int timeIndex) =>
      _notificationId(medicineId, timeIndex);

  /// 오늘 해당 시각이 지났으면 내일로 설정
  static tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> _showLocal(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    await _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: _notificationDetails,
    );
  }
}
