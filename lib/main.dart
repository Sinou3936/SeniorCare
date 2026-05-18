import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/mode_select_screen.dart';
import 'screens/senior/senior_main_screen.dart';
import 'screens/family/family_main_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  await AuthService.signInAnonymously();
  final savedMode = await PrefsService.loadMode();
  // 알림 초기화·알람 재등록은 runApp 이후 백그라운드 실행 (getToken 블로킹 방지)
  unawaited(_initNotificationsAndAlarms(savedMode));
  runApp(SeniorCareApp(initialMode: savedMode));
}

Future<void> _initNotificationsAndAlarms(String? mode) async {
  await NotificationService.init();
  if (mode == 'senior') {
    final medicines = await FirestoreService.getActiveMedicines();
    await NotificationService.rescheduleAllAlarms(medicines);
  }
}

class SeniorCareApp extends StatelessWidget {
  final String? initialMode;
  const SeniorCareApp({super.key, this.initialMode});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (initialMode == 'senior') {
      home = const SeniorMainScreen();
    } else if (initialMode == 'family') {
      home = const FamilyMainScreen();
    } else {
      home = const ModeSelectScreen();
    }

    return MaterialApp(
      title: '약봄',
      debugShowCheckedModeBanner: false,
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
