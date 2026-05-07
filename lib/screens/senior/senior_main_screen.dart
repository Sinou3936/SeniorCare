import 'package:flutter/material.dart';
import 'senior_home_screen.dart';
import 'senior_medicine_screen.dart';
import 'senior_hospital_screen.dart';

class SeniorMainScreen extends StatefulWidget {
  const SeniorMainScreen({super.key});

  @override
  State<SeniorMainScreen> createState() => _SeniorMainScreenState();
}

class _SeniorMainScreenState extends State<SeniorMainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    SeniorHomeScreen(),
    SeniorMedicineScreen(),
    SeniorHospitalScreen(),
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
        iconSize: 32,
        selectedItemColor: const Color(0xFF4A90D9),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.medication_rounded), label: '약 관리'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital_rounded), label: '병원'),
        ],
      ),
    );
  }
}
