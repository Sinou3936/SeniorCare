import 'package:flutter/material.dart';

class _NotificationItem {
  final String id;
  final String message;
  final DateTime time;
  bool isRead;

  _NotificationItem({
    required this.id,
    required this.message,
    required this.time,
    this.isRead = false,
  });
}

class FamilyNotificationScreen extends StatefulWidget {
  const FamilyNotificationScreen({super.key});

  @override
  State<FamilyNotificationScreen> createState() => _FamilyNotificationScreenState();
}

class _FamilyNotificationScreenState extends State<FamilyNotificationScreen> {
  final List<_NotificationItem> _items = [
    _NotificationItem(
      id: '1',
      message: '당뇨약 점심 복용을 하지 않으셨어요',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    _NotificationItem(
      id: '2',
      message: '혈압약 저녁 복용을 하지 않으셨어요',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    _NotificationItem(
      id: '3',
      message: '비타민 취침 복용을 하지 않으셨어요',
      time: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      isRead: true,
    ),
    _NotificationItem(
      id: '4',
      message: '혈압약 아침 복용을 하지 않으셨어요',
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90D9),
        title: Text(
          unread > 0 ? '알림 ($unread)' : '알림',
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => setState(() {
              for (final item in _items) {
                item.isRead = true;
              }
            }),
            child: const Text(
              '모두 읽음',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text('알림이 없어요', style: TextStyle(fontSize: 20, color: Color(0xFF999999))),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _items.length,
              separatorBuilder: (context, i) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = _items[i];
                return GestureDetector(
                  onTap: () => setState(() => item.isRead = true),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.isRead ? Colors.white : const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935).withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.medication_liquid_rounded,
                                size: 28,
                                color: Color(0xFFE53935),
                              ),
                            ),
                            if (!item.isRead)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4A90D9),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.message,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: item.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(item.time),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
