import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';
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
  bool? _online; // null=확인중, true=온라인, false=오프라인(진입 차단)

  final _screens = const [
    FamilyHomeScreen(),
    FamilyNotificationScreen(),
    FamilyHospitalScreen(),
    FamilySettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  // 가족 모드는 부모 복약 현황을 실시간으로 봐야 하므로 오프라인 진입을 막는다.
  // (오프라인이면 오래된 캐시 데이터가 보여 "드신 줄 알았는데" 오인 위험)
  Future<void> _checkConnection() async {
    setState(() => _online = null);
    final ok = await ConnectivityService.isOnline();
    if (mounted) setState(() => _online = ok);
  }

  @override
  Widget build(BuildContext context) {
    if (_online == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE8896A))),
      );
    }
    if (_online == false) {
      return Scaffold(
        body: OfflineGate(
          message: '가족 모드는 부모님의 복약 현황을\n실시간으로 확인해야 해서\nWi-Fi나 데이터 연결이 필요해요.',
          onRetry: _checkConnection,
        ),
      );
    }
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
