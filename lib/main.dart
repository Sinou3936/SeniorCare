import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/mode_select_screen.dart';
import 'screens/senior/senior_main_screen.dart';
import 'screens/senior/medicine_alarm_screen.dart';
import 'screens/family/family_main_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/prefs_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// 알람 인텐트로 깨어났을 때 라우팅
/// - 화면 OFF(자동실행) → 풀스크린 알람 화면
/// - 화면 ON(배너 탭) → 홈 화면으로
void _onAlarmRoute(String time, bool screenOn) {
  if (screenOn) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SeniorMainScreen()),
      (route) => false,
    );
  } else {
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => MedicineAlarmScreen(time: time),
    ));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  // 익명 인증 — 오프라인 첫 실행 등으로 실패해도 앱은 떠야 하므로 막지 않음
  // (이미 로그인된 폰은 currentUser 캐시로 네트워크 없이 통과)
  try {
    await AuthService.signInAnonymously();
  } catch (_) {
    // 오프라인 등 실패 시 계속 진행 — 온라인 복귀/다음 실행 때 인증
  }

  await NotificationService.init();

  // 백그라운드 앱이 알람으로 깨어났을 때(onNewIntent) → 화면상태로 분기
  NotificationService.onAlarmTapped = _onAlarmRoute;

  // 콜드스타트: 알람 인텐트로 실행됐고 + 화면이 꺼져 있었을 때만 풀스크린 알람 화면으로 시작
  // (화면 ON에서 배너 탭으로 실행된 경우는 일반 홈으로) — 전부 로컬, 네트워크 무관
  final launchPayload = await NotificationService.getLaunchAlarmTime();
  String? alarmTime;
  if (launchPayload != null) {
    final screenOn = await NotificationService.wasScreenOnAtLaunch();
    if (!screenOn) alarmTime = launchPayload;
  }

  final savedMode = await PrefsService.loadMode();

  // ① UI(풀스크린 알람 포함)를 네트워크 조회보다 먼저 띄운다.
  //    Firestore .get()이 오프라인에서 멈추던 탓에 runApp이 막혀 풀스크린·벨소리가
  //    네트워크 켤 때까지 안 뜨던 문제(B5) 해결.
  runApp(SeniorCareApp(initialMode: savedMode, alarmTime: alarmTime));

  // ② 알람 재등록은 UI를 띄운 뒤 백그라운드에서 (await로 안 막음).
  //    오프라인이면 조용히 실패 — 이미 등록된 알람은 유지되고 다음 온라인 때 재등록.
  if (savedMode == 'senior') {
    _rescheduleAlarmsInBackground();
  }
}

/// 시니어 모드 콜드스타트 시 알람 재등록 (UI 비차단, 오프라인 안전)
Future<void> _rescheduleAlarmsInBackground() async {
  try {
    final medicines = await FirestoreService.getActiveMedicines();
    final appointments = await FirestoreService.getUpcomingAppointments();
    final notifEnabled = await PrefsService.loadNotificationEnabled();
    final hospitalNotifEnabled = await PrefsService.loadHospitalNotificationEnabled();
    // cancelAll() 포함된 rescheduleAllAlarms 먼저 실행 후 병원 알람 재등록
    if (notifEnabled) await NotificationService.rescheduleAllAlarms(medicines);
    if (hospitalNotifEnabled) {
      await NotificationService.rescheduleAppointmentAlarms(appointments);
    }
  } catch (_) {
    // 오프라인 등 실패 시 무시 — 기존 알람 유지, 다음 실행/온라인 복귀 때 재등록
  }
}

class SeniorCareApp extends StatelessWidget {
  final String? initialMode;
  final String? alarmTime;
  const SeniorCareApp({super.key, this.initialMode, this.alarmTime});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (alarmTime != null) {
      // 화면 OFF 상태에서 알람으로 실행 → MedicineAlarmScreen 바로 표시
      home = MedicineAlarmScreen(time: alarmTime!);
    } else if (initialMode == 'senior') {
      home = const SeniorMainScreen();
    } else if (initialMode == 'family') {
      home = const FamilyMainScreen();
    } else {
      home = const ModeSelectScreen();
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '약봄',
      debugShowCheckedModeBanner: false,
      // 시스템 글자 크기 반영하되 상한 1.5배 (시니어 접근성 + 레이아웃 보호)
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.of(context)
              .textScaler
              .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.5),
        ),
        child: child!,
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8896A),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE8896A),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      locale: const Locale('ko', 'KR'),
      home: home,
    );
  }
}
