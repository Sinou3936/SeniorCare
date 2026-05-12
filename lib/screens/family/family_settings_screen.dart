import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/prefs_service.dart';
import '../mode_select_screen.dart';

class FamilySettingsScreen extends StatefulWidget {
  const FamilySettingsScreen({super.key});

  @override
  State<FamilySettingsScreen> createState() => _FamilySettingsScreenState();
}

class _FamilySettingsScreenState extends State<FamilySettingsScreen> {
  bool _notificationEnabled = true;
  String? _linkedSeniorUid;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      PrefsService.loadNotificationEnabled(),
      FirestoreService.getLinkedSeniorUid(),
    ]);
    if (mounted) {
      setState(() {
        _notificationEnabled = results[0] as bool;
        _linkedSeniorUid = results[1] as String?;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _Header(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // ?Ä?Ä ?ÖÍ∑∏?àÏù¥??CTA Î∞∞ÎÑà ?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä
                        _UpgradeBanner(
                            onTap: () =>
                                _linkWithGoogle()),
                        const SizedBox(height: 24),

                        // ?Ä?Ä Î∂ÄÎ™®Îãò ?∞Í≤∞ ?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä
                        _SectionTitle('Î∂ÄÎ™®Îãò ?∞Í≤∞'),
                        const SizedBox(height: 10),
                        _LinkedSeniorCard(
                          linkedUid: _linkedSeniorUid,
                          onUnlink: () => _confirmUnlink(),
                        ),

                        const SizedBox(height: 24),

                        // ?Ä?Ä ??Í∏∞Îä• ?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä
                        _SectionTitle('??Í∏∞Îä•'),
                        const SizedBox(height: 10),
                        _Card(children: [
                          _SwitchTile(
                            icon: Icons.notifications_outlined,
                            iconColor: const Color(0xFFE8896A),
                            title: 'ÎØ∏Î≥µ???åÎ¶º',
                            subtitle: 'Î∂ÄÎ™®Îãò???ΩÏùÑ ???úÏÖ®?????åÎ¶º',
                            value: _notificationEnabled,
                            onChanged: (v) async {
                              setState(() => _notificationEnabled = v);
                              await PrefsService.saveNotificationEnabled(v);
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
                              side: const BorderSide(
                                  color: Color(0xFFCCCCCC)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.swap_horiz_rounded,
                                color: Color(0xFF999999)),
                            label: const Text(
                              'Î™®Îìú ?†ÌÉù ?îÎ©¥?ºÎ°ú ?åÏïÑÍ∞ÄÍ∏?,
                              style: TextStyle(
                                  fontSize: 16, color: Color(0xFF999999)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'SeniorCare v1.0.0',
                            style:
                                TextStyle(fontSize: 14, color: Colors.grey[400]),
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

  Future<void> _confirmUnlink() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('?∞Í≤∞ ?¥Ï†ú',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: const Text(
          '?∞Í≤∞???¥Ï†ú?òÎ©¥ Î∂ÄÎ™®Îãò??nÎ≥µÏö© ?ÑÌô©?????¥ÏÉÅ Î≥????ÜÏñ¥??',
          style: TextStyle(fontSize: 18, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ï∑®ÏÜå', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('?¥Ï†ú',
                style: TextStyle(fontSize: 18, color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await FirestoreService.unlinkFromSenior();
      await PrefsService.clearMode();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
          (_) => false,
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
          content: Text('Google Í≥ÑÏ†ï???∞Í≤∞?êÏñ¥?? ?¨ÏÑ§ÏπòÌï¥???∞Í≤∞???†Ï??ºÏöî.',
              style: TextStyle(fontSize: 16)),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ));
      case 'cancelled':
        break;
      case 'already_in_use':
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('?¥Î? ?§Î•∏ Í≥ÑÏ†ï???∞Í≤∞??Google Í≥ÑÏ†ï?¥Ïóê??',
              style: TextStyle(fontSize: 16)),
          behavior: SnackBarBehavior.floating,
        ));
      default:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('?∞Í≤∞ Ï§??§Î•òÍ∞Ä Î∞úÏÉù?àÏñ¥?? ?§Ïãú ?úÎèÑ?¥Ï£º?∏Ïöî.',
              style: TextStyle(fontSize: 16)),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

}

// ?Ä?Ä Header ?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä

class _Header extends StatelessWidget {
  const _Header();

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
                    '?§Ï†ï',
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
                      child: const Icon(Icons.family_restroom_rounded,
                          size: 44, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Í∞ÄÏ°?Î≥µÏö© ?ïÏù∏',
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
                              'Î≥¥Ìò∏??Î™®Îìú',
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

// ?Ä?Ä ?ÖÍ∑∏?àÏù¥??CTA Î∞∞ÎÑà ?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä

class _UpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF1565C0), size: 22),
              const SizedBox(width: 8),
              const Text(
                '?¨Ïã§?âÎßà??ÏΩîÎìúÎ•??§Ïãú ?ÖÎ†•?¥Ïïº ?¥Ïöî',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Google Í≥ÑÏ†ï???∞Í≤∞?òÎ©¥ ?±ÏùÑ ÍªêÎã§ ÏºúÎèÑ\nÎ∂ÄÎ™®ÎãòÍ≥??êÎèô?ºÎ°ú ?∞Í≤∞?ºÏöî.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF1976D2),
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
                'GoogleÎ°??ÅÍµ¨ ?∞Í≤∞?òÍ∏∞',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ?Ä?Ä Î∂ÄÎ™®Îãò ?∞Í≤∞ Ïπ¥Îìú ?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä

class _LinkedSeniorCard extends StatelessWidget {
  final String? linkedUid;
  final VoidCallback onUnlink;

  const _LinkedSeniorCard({required this.linkedUid, required this.onUnlink});

  @override
  Widget build(BuildContext context) {
    final isLinked = linkedUid != null;

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
                  color: isLinked
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : const Color(0xFF999999).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLinked
                      ? Icons.elderly_rounded
                      : Icons.person_off_outlined,
                  color: isLinked
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF999999),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Î∂ÄÎ™®Îãò ?∞Í≤∞ ?ÅÌÉú',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    isLinked ? '?∞Í≤∞?? : '?∞Í≤∞??Î∂ÄÎ™®Îãò???ÜÏñ¥??,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isLinked ? FontWeight.w600 : FontWeight.normal,
                      color: isLinked
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isLinked) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onUnlink,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                  side: const BorderSide(color: Color(0xFFE53935)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.link_off_rounded, size: 20),
                label: const Text(
                  '?∞Í≤∞ ?¥Ï†ú',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ?Ä?Ä Í≥µÌÜµ ?ÑÏ†Ø ?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä?Ä

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
