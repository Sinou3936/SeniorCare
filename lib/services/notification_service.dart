import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

// 백그라운드 메시지 핸들러 (top-level 함수 필수)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'medicine_reminders';
  static const _channelName = '복약 알림';

  static Future<void> init() async {
    // 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 알림 권한 요청
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 로컬 알림 초기화
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (_) {},
    );

    // 알림 채널 생성 (Android 8+)
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

    // 포그라운드 메시지 수신 → 로컬 알림으로 표시
    FirebaseMessaging.onMessage.listen(_showLocal);

    // FCM 토큰 저장
    final token = await _messaging.getToken();
    if (token != null) await FirestoreService.saveFcmToken(token);

    // 토큰 갱신 시 자동 업데이트
    _messaging.onTokenRefresh.listen(FirestoreService.saveFcmToken);
  }

  static Future<void> _showLocal(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    await _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
