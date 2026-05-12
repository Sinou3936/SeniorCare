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
  static const _channelName = 'Î≥µÏïΩ ?åÎ¶º';

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

    // timezone Ï¥àÍ∏∞??    tz_data.initializeTimeZones();
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

    // ?ïÌôï???åÎûå Í∂åÌïú ?îÏ≤≠ (Android 12+)
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    FirebaseMessaging.onMessage.listen(_showLocal);

    final token = await _messaging.getToken();
    if (token != null) await FirestoreService.saveFcmToken(token);
    _messaging.onTokenRefresh.listen(FirestoreService.saveFcmToken);
  }

  /// ??Î≥µÏö© ?åÎ¶º ?§Ï?Ï§ÑÎßÅ ????Ï∂îÍ?/?òÏ†ï ???∏Ï∂ú
  /// [medicineId] Í∏∞Ï??ºÎ°ú Í∏∞Ï°¥ ?åÎ¶º Ï∑®ÏÜå ???¨Îì±Î°?  static Future<void> scheduleMedicineAlarms({
    required String medicineId,
    required String medicineName,
    required List<String> times, // "HH:mm" ?ïÏãù
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
          title: 'Î≥µÏïΩ ?åÎ¶º',
          body: '$medicineName ?úÏã§ ?úÍ∞Ñ?¥Ïóê??',
          scheduledDate: scheduledTime,
          notificationDetails: _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        // ?ïÌôï???åÎûå Í∂åÌïú ?ÜÏùÑ ??inexactÎ°??¥Î∞±
        await _local.zonedSchedule(
          id: id,
          title: 'Î≥µÏïΩ ?åÎ¶º',
          body: '$medicineName ?úÏã§ ?úÍ∞Ñ?¥Ïóê??',
          scheduledDate: scheduledTime,
          notificationDetails: _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  /// ????†ú ???¥Îãπ ?ΩÏùò Î™®Îì† ?åÎ¶º Ï∑®ÏÜå
  static Future<void> cancelMedicineAlarms(String medicineId) async {
    // ÏµúÎ? ?úÍ∞Ñ?Ä ?òÎßå??Ï∑®ÏÜå ?úÎèÑ (?ÑÏπ®/?êÏã¨/?Ä??Ï∑®Ïπ® = ÏµúÎ? 4Í∞?
    for (int i = 0; i < 10; i++) {
      await _local.cancel(id: _notificationId(medicineId, i));
    }
  }

  /// medicineId + ?úÍ∞Ñ?Ä ?∏Îç±?§Î°ú Í≥†Ïú† ?åÎ¶º ID ?ùÏÑ±
  static int _notificationId(String medicineId, int timeIndex) {
    return (medicineId.hashCode.abs() % 100000) * 10 + timeIndex;
  }

  // ignore: invalid_use_of_visible_for_testing_member
  static int notificationIdForTest(String medicineId, int timeIndex) =>
      _notificationId(medicineId, timeIndex);

  /// ?§Îäò ?¥Îãπ ?úÍ∞Å??ÏßÄ?¨ÏúºÎ©??¥ÏùºÎ°??§Ï†ï
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
