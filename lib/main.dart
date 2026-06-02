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

/// payload("08:00") → MedicineAlarmScreen으로 이동
void _openAlarmScreen(String time) {
  navigatorKey.currentState?.push(MaterialPageRoute(
    builder: (_) => MedicineAlarmScreen(time: time),
  ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  await AuthService.signInAnonymously();
  await NotificationService.init();

  // 백그라운드 앱이 알람으로 깨어났을 때(onNewIntent) → 알람 화면으로 이동
  NotificationService.onAlarmTapped = _openAlarmScreen;

  // 콜드스타트: 알람 인텐트로 실행됐고 + 화면이 꺼져 있었을 때만 풀스크린 알람 화면으로 시작
  // (화면 ON에서 배너 탭으로 실행된 경우는 일반 홈으로)
  final launchPayload = await NotificationService.getLaunchAlarmTime();
  String? alarmTime;
  if (launchPayload != null) {
    final screenOn = await NotificationService.wasScreenOnAtLaunch();
    if (!screenOn) alarmTime = launchPayload;
  }

  final savedMode = await PrefsService.loadMode();
  if (savedMode == 'senior') {
    final medicines = await FirestoreService.getActiveMedicines();
    final appointments = await FirestoreService.getUpcomingAppointments();
    final notifEnabled = await PrefsService.loadNotificationEnabled();
    final hospitalNotifEnabled = await PrefsService.loadHospitalNotificationEnabled();
    // cancelAll() 포함된 rescheduleAllAlarms 먼저 실행 후 병원 알람 재등록
    if (notifEnabled) await NotificationService.rescheduleAllAlarms(medicines);
    if (hospitalNotifEnabled) await NotificationService.rescheduleAppointmentAlarms(appointments);
  }
  runApp(SeniorCareApp(initialMode: savedMode, alarmTime: alarmTime));
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
      // 시스템 글자 크기 설정 무시 — 앱 자체 폰트 크기로 고정
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
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
