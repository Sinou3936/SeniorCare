import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/prefs_service.dart';
import '../mode_select_screen.dart';

class FamilySettingsScreen extends StatelessWidget {
  const FamilySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Header(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── 계정 ──────────────────────────────────────
                  _SectionTitle('계정'),
                  const SizedBox(height: 10),
                  _Card(children: [
                    _Tile(
                      icon: Icons.account_circle_outlined,
                      iconColor: const Color(0xFF4A90D9),
                      title: '계정 상태',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '보호자 모드',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                      ),
                    ),
                    _divider(),
                    _Tile(
                      icon: Icons.g_mobiledata_rounded,
                      iconColor: const Color(0xFF4285F4),
                      title: 'Google 계정 연결',
                      subtitle: '재실행 시 자동 로그인돼요',
                      onTap: () => _showComingSoon(context, 'Google 계정 연결'),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── 부모님 연결 ───────────────────────────────
                  _SectionTitle('부모님 연결'),
                  const SizedBox(height: 10),
                  _Card(children: [
                    _Tile(
                      icon: Icons.people_outline_rounded,
                      iconColor: const Color(0xFF4A90D9),
                      title: '연결된 부모님 보기',
                      onTap: () => _showComingSoon(context, '연결된 부모님 보기'),
                    ),
                    _divider(),
                    _Tile(
                      icon: Icons.link_off_rounded,
                      iconColor: const Color(0xFFE53935),
                      title: '연결 해제',
                      subtitle: '연결을 끊으면 복용 현황을 볼 수 없어요',
                      titleColor: const Color(0xFFE53935),
                      onTap: () => _confirmUnlink(context),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── 앱 설정 ───────────────────────────────────
                  _SectionTitle('앱 설정'),
                  const SizedBox(height: 10),
                  _Card(children: [
                    _Tile(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFF4A90D9),
                      title: '미복용 알림',
                      subtitle: '부모님이 약을 안 드셨을 때 알림',
                      onTap: () => _showComingSoon(context, '알림 설정'),
                    ),
                  ]),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _switchMode(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCCCCCC)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.swap_horiz_rounded,
                          color: Color(0xFF999999)),
                      label: const Text(
                        '모드 선택 화면으로 돌아가기',
                        style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'SeniorCare v1.0.0',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _divider() =>
      const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0));

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 기능은 준비 중이에요',
            style: const TextStyle(fontSize: 16)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmUnlink(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('연결 해제',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: const Text(
          '연결을 해제하면 부모님의\n복용 현황을 더 이상 볼 수 없어요.',
          style: TextStyle(fontSize: 18, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('해제',
                style: TextStyle(fontSize: 18, color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await FirestoreService.unlinkFromSenior();
      await PrefsService.clearMode();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _switchMode(BuildContext context) async {
    await PrefsService.clearMode();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
        (_) => false,
      );
    }
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A90D9), Color(0xFF6BAEE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    '설정',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_rounded,
                        color: Colors.white, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '가족 복용 확인',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF69F0AE),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '보호자 모드',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 공통 위젯 ────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF666666),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? const Color(0xFF1A1A2E),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF999999)),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFCCCCCC), size: 24),
          ],
        ),
      ),
    );
  }
}
