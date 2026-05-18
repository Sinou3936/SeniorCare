import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
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
  int _linkedFamilyCount = 0;

  @override
  void initState() {
    super.initState();
    PrefsService.loadNotificationEnabled()
        .then((v) => setState(() => _notificationEnabled = v));
    FirestoreService.getLinkedFamilyUids()
        .then((list) => setState(() => _linkedFamilyCount = list.length));
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
                  const SizedBox(height: 20),

                  // ── 업그레이드 CTA 배너 (익명일 때만) ──────────────
                  if (isAnonymous) ...[
                    _UpgradeBanner(onTap: () => _linkWithGoogle()),
                    const SizedBox(height: 24),
                  ],

                  // ── 보호자 관리 ───────────────────────────────────
                  _SectionTitle('보호자 관리'),
                  const SizedBox(height: 10),
                  _GuardianCard(
                    linkedCount: _linkedFamilyCount,
                    onCodeTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SeniorMyCodeScreen()),
                    ),
                    onManageTap: () => _showLinkedFamilies(),
                  ),

                  const SizedBox(height: 24),

                  // ── 데이터 관리 ───────────────────────────────────
                  _SectionTitle('데이터 관리'),
                  const SizedBox(height: 10),
                  _DataActionGrid(
                    onBackup: () => _showComingSoon('데이터 백업'),
                    onDeviceChange: () => _showDeviceChangeInfo(),
                    onReset: () => _confirmClearData(),
                  ),

                  const SizedBox(height: 24),

                  // ── 앱 기능 ───────────────────────────────────────
                  _SectionTitle('앱 기능'),
                  const SizedBox(height: 10),
                  _Card(children: [
                    _SwitchTile(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFFE8896A),
                      title: '복약 알림',
                      subtitle: '약 드실 시간에 알림을 보내드려요',
                      value: _notificationEnabled,
                      onChanged: (v) async {
                        setState(() => _notificationEnabled = v);
                        await PrefsService.saveNotificationEnabled(v);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.notification_add_outlined,
                          color: Color(0xFFE8896A), size: 28),
                      title: const Text('알림 테스트',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      subtitle: const Text('5초 후 예약 알림 발송',
                          style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
                      onTap: () async {
                        await NotificationService.sendTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('5초 후 알림이 옵니다'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ]),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _switchMode(),
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

  Future<void> _showLinkedFamilies() async {
    final uids = await FirestoreService.getLinkedFamilyUids();
    if (!mounted) return;
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
                      backgroundColor: Color(0xFFE8896A),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text('보호자 ${e.key + 1}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${e.value.substring(0, 8)}...',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF999999)),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _confirmUnlinkFamily(e.value, e.key + 1);
                      },
                      child: const Text('해제',
                          style: TextStyle(
                              color: Color(0xFFE53935), fontSize: 16)),
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

  Future<void> _confirmUnlinkFamily(String familyUid, int index) async {
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
    if (ok == true && mounted) {
      await FirestoreService.unlinkFamily(familyUid);
      final uids = await FirestoreService.getLinkedFamilyUids();
      if (mounted) {
        setState(() => _linkedFamilyCount = uids.length);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('보호자 연결이 해제됐어요', style: TextStyle(fontSize: 16)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _switchMode() async {
    await PrefsService.clearMode();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _linkWithGoogle() async {
    final result = await AuthService.linkWithGoogle();
    if (!mounted) return;
    switch (result) {
      case 'success':
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Google 계정이 연결됐어요! 이제 기기를 바꿔도 데이터가 유지돼요.',
              style: TextStyle(fontSize: 16)),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ));
      case 'cancelled':
        break;
      case 'already_in_use':
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('이미 다른 계정에 연결된 Google 계정이에요.',
              style: TextStyle(fontSize: 16)),
          behavior: SnackBarBehavior.floating,
        ));
      default:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('연결 중 오류가 발생했어요. 다시 시도해주세요.',
              style: TextStyle(fontSize: 16)),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 기능은 준비 중이에요',
            style: const TextStyle(fontSize: 16)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmClearData() async {
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
    if (ok == true && mounted) {
      await FirestoreService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 데이터가 초기화됐어요', style: TextStyle(fontSize: 16)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeviceChangeInfo() {
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
              _linkWithGoogle();
            },
            child: const Text('Google 연결',
                style: TextStyle(fontSize: 18, color: Color(0xFF4285F4))),
          ),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isAnonymous;
  const _Header({required this.isAnonymous});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8896A), Color(0xFF6BAEE8)],
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
                      child: const Icon(Icons.elderly_rounded,
                          size: 44, color: Colors.white),
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

// ── 업그레이드 CTA 배너 ──────────────────────────────────────────────────────

class _UpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF9800), size: 22),
              const SizedBox(width: 8),
              const Text(
                '기기를 바꾸면 데이터가 사라져요',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Google 계정을 연결하면 기기를 바꿔도\n약·병원 정보가 그대로 유지돼요.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF795548),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
              label: const Text(
                'Google 계정 연결하기',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 보호자 카드 ──────────────────────────────────────────────────────────────

class _GuardianCard extends StatelessWidget {
  final int linkedCount;
  final VoidCallback onCodeTap;
  final VoidCallback onManageTap;

  const _GuardianCard({
    required this.linkedCount,
    required this.onCodeTap,
    required this.onManageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8896A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_rounded,
                    color: Color(0xFFE8896A), size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '연결된 보호자',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    linkedCount == 0 ? '아직 연결된 보호자가 없어요' : '$linkedCount명 연결됨',
                    style: TextStyle(
                      fontSize: 14,
                      color: linkedCount == 0
                          ? const Color(0xFF999999)
                          : const Color(0xFFE8896A),
                      fontWeight: linkedCount > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.qr_code_rounded,
                  label: '내 코드 보기',
                  color: const Color(0xFFE8896A),
                  onTap: onCodeTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.manage_accounts_rounded,
                  label: '보호자 관리',
                  color: linkedCount > 0
                      ? const Color(0xFFE8896A)
                      : const Color(0xFFBBBBBB),
                  onTap: onManageTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 데이터 관리 그리드 ────────────────────────────────────────────────────────

class _DataActionGrid extends StatelessWidget {
  final VoidCallback onBackup;
  final VoidCallback onDeviceChange;
  final VoidCallback onReset;

  const _DataActionGrid({
    required this.onBackup,
    required this.onDeviceChange,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DataActionTile(
            icon: Icons.cloud_upload_outlined,
            label: '데이터 백업',
            color: const Color(0xFFE8896A),
            badge: '준비중',
            onTap: onBackup,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DataActionTile(
            icon: Icons.smartphone_rounded,
            label: '기기 변경\n안내',
            color: const Color(0xFFFF9800),
            onTap: onDeviceChange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DataActionTile(
            icon: Icons.delete_outline_rounded,
            label: '데이터\n초기화',
            color: const Color(0xFFE53935),
            onTap: onReset,
          ),
        ),
      ],
    );
  }
}

class _DataActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _DataActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF999999),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 공통 위젯 ────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF999999))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: iconColor,
          ),
        ],
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
