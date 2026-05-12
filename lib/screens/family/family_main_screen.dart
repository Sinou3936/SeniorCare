import 'package:flutter/material.dart';
import 'family_home_screen.dart';
import 'family_notification_screen.dart';
import 'family_hospital_screen.dart';
import 'family_settings_screen.dart';

class FamilyMainScreen extends StatefulWidget {
  const FamilyMainScreen({super.key});

  @override
  State<FamilyMainScreen> createState() => _FamilyMainScreenState();
}

class _FamilyMainScreenState extends State<FamilyMainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    FamilyHomeScreen(),
    FamilyNotificationScreen(),
    FamilyHospitalScreen(),
    FamilySettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedFontSize: 16,
        unselectedFontSize: 14,
        iconSize: 30,
        selectedItemColor: const Color(0xFFE8896A),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: '알림',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_rounded),
            label: '병원',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
