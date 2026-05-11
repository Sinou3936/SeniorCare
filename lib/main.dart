import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/mode_select_screen.dart';
import 'screens/senior/senior_main_screen.dart';
import 'screens/family/family_main_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService.signInAnonymously();
  await NotificationService.init();
  final savedMode = await PrefsService.loadMode();
  runApp(SeniorCareApp(initialMode: savedMode));
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
      title: 'SeniorCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A90D9),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: home,
    );
  }
}
