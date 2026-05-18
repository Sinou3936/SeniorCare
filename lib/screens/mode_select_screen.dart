import 'package:flutter/material.dart';
import 'senior/senior_main_screen.dart';
import 'family/family_code_input_screen.dart';
import '../services/prefs_service.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8896A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 72),
              const SizedBox(height: 16),
              const Text(
                'SeniorCare',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '건강한 하루를 함께해요',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 64),
              _ModeButton(
                icon: Icons.elderly,
                label: '내 건강 관리',
                subtitle: '약 복용 · 병원 예약',
                color: Colors.white,
                textColor: const Color(0xFFE8896A),
                onTap: () async {
                  await PrefsService.saveMode('senior');
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SeniorMainScreen()),
                    );
                  }
                },

              ),
              const SizedBox(height: 20),
              _ModeButton(
                icon: Icons.family_restroom,
                label: '가족 복용 확인',
                subtitle: '부모님 복용 현황 확인',
                color: Colors.white24,
                textColor: Colors.white,
                border: Border.all(color: Colors.white, width: 2),
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const FamilyCodeInputScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color textColor;
  final BoxBorder? border;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.textColor,
    this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: border,
        ),
        child: Column(
          children: [
            Icon(icon, size: 52, color: textColor),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 15, color: textColor.withValues(alpha:0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
