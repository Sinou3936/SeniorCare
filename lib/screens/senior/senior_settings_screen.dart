import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/prefs_service.dart';
import '../mode_select_screen.dart';
import 'senior_my_code_screen.dart';

class SeniorSettingsScreen extends StatefulWidget {
  const SeniorSettingsScreen({super.key});

  @override
  State<SeniorSettingsScreen> createState() => _SeniorSettingsScreenState();
}

class _SeniorSettingsScreenState extends State<SeniorSettingsScreen> {
  bool _notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    PrefsService.loadNotificationEnabled().then(
      (v) => setState(() => _notificationEnabled = v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAnonymous = AuthService.currentUser?.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Header(isAnonymous: isAnonymous),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAnonymous
                              ? const Color(0xFFFF9800).withValues(alpha: 0.12)
                              : const Color(0xFF4CAF50).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAnonymous ? '익명 사용자' : 'Google 연결됨',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isAnonymous
                                ? const Color(0xFFFF9800)
                                : const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ),
                    _divider(),
                    _Tile(
                      icon: Icons.g_mobiledata_rounded,
                      iconColor: const Color(0xFF4285F4),
                      title: 'Google 계정 연결',
                      subtitle: '기기를 바꿔도 데이터가 유지돼요',
                      onTap: () => _showComingSoon(context, 'Google 계정 연결'),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── 보호자 관리 ───────────────────────────────
                  _SectionTitle('보호자 관리'),
                  const SizedBox(height: 10),
                  _Card(children: [
                    _Tile(
                      icon: Icons.qr_code_rounded,
                      iconColor: const Color(0xFF4A90D9),
                      title: '내 연결 코드 보기',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SeniorMyCodeScreen()),
                      ),
                    ),
                    _divider(),
                    _Tile(
                      icon: Icons.people_outline_rounded,
                      iconColor: const Color(0xFF4A90D9),
                      title: '연결된 보호자 보기',
                      onTap: () => _showLinkedFamilies(context),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ── 데이터 관리 ───────────────────────────────
                  _SectionTitle('데이터 관리'),
                  const SizedBox(height: 10),
                  _Card(children: [
                    _Tile(
                      icon: Icons.smartphone_rounded,
                      iconColor: const Color(0xFF4A90D9),
                      title: '기기 변경 안내',
                      onTap: () => _showDeviceChangeInfo(context),
                    ),
                    _divider(),
                    _Tile(
                      icon: Icons.delete_outline_rounded,
                      iconColor: const Color(0xFFE53935),
                      title: '데이터 초기화',
                      subtitle: '모든 약·병원 정보가 삭제돼요',
                      titleColor: const Color(0xFFE53935),
                      onTap: () => _confirmClearData(context),
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
                      title: '복약 알림',
                      trailing: Switch(
                        value: _notificationEnabled,
                        onChanged: (v) async {
                          setState(() => _notificationEnabled = v);
                          await PrefsService.saveNotificationEnabled(v);
                        },
                        activeThumbColor: const Color(0xFF4A90D9),
                      ),
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

  Future<void> _showLinkedFamilies(BuildContext context) async {
    final uids = await FirestoreService.getLinkedFamilyUids();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('연결된 보호자',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: uids.isEmpty
            ? const Text('연결된 보호자가 없어요',
                style: TextStyle(fontSize: 18, color: Color(0xFF999999)))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: uids.asMap().entries.map((e) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF4A90D9),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text('보호자 ${e.key + 1}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${e.value.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _confirmUnlinkFamily(context, e.value, e.key + 1);
                      },
                      child: const Text('해제',
                          style: TextStyle(color: Color(0xFFE53935), fontSize: 16)),
                    ),
                  );
                }).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnlinkFamily(
      BuildContext context, String familyUid, int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('보호자 연결 해제',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: Text(
          '보호자 $index 의 연결을 해제할까요?',
          style: const TextStyle(fontSize: 18),
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
      await FirestoreService.unlinkFamily(familyUid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('보호자 연결이 해제됐어요', style: TextStyle(fontSize: 16)),
            behavior: SnackBarBehavior.floating,
          ),
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

  Widget _divider() => const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0));

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 기능은 준비 중이에요', style: const TextStyle(fontSize: 16)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('데이터 초기화',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: const Text(
          '모든 약과 병원 예약 정보가\n영구적으로 삭제돼요.\n\n이 작업은 되돌릴 수 없어요.',
          style: TextStyle(fontSize: 18, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('초기화',
                style: TextStyle(fontSize: 18, color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await FirestoreService.clearAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 데이터가 초기화됐어요', style: TextStyle(fontSize: 16)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeviceChangeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('기기 변경 안내',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoItem(
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFFF9800),
              text: '현재 익명 로그인 상태예요.',
            ),
            const SizedBox(height: 12),
            _InfoItem(
              icon: Icons.smartphone_rounded,
              color: const Color(0xFFE53935),
              text: '기기를 바꾸면 약·병원 데이터가\n모두 사라져요.',
            ),
            const SizedBox(height: 12),
            _InfoItem(
              icon: Icons.g_mobiledata_rounded,
              color: const Color(0xFF4285F4),
              text: 'Google 계정을 연결하면\n어떤 기기에서도 이어서 사용할 수 있어요.',
            ),
            const SizedBox(height: 12),
            _InfoItem(
              icon: Icons.backup_rounded,
              color: const Color(0xFF4A90D9),
              text: '기기 변경 전 Google 계정 연결을\n먼저 해두세요.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon(context, 'Google 계정 연결');
            },
            child: const Text('Google 연결',
                style: TextStyle(fontSize: 18, color: Color(0xFF4285F4))),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isAnonymous;
  const _Header({required this.isAnonymous});

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
                    child: const Icon(Icons.settings_rounded, color: Colors.white, size: 28),
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
                        Icons.elderly_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '내 건강 관리',
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
                              decoration: BoxDecoration(
                                color: isAnonymous
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFF69F0AE),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAnonymous ? '익명으로 사용 중' : 'Google 계정 연결됨',
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
                      style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC), size: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoItem({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4)),
        ),
      ],
    );
  }
}
