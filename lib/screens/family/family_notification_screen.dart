import 'package:flutter/material.dart';
import '../../models/app_notification.dart';
import '../../services/firestore_service.dart';
import '../../utils/time_utils.dart';

class FamilyNotificationScreen extends StatelessWidget {
  const FamilyNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: FirestoreService.watchNotifications(),
      builder: (context, snap) {
        final notifications = snap.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF4A90D9),
            title: Text(
              unreadCount > 0 ? '알림 ($unreadCount)' : '알림',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            automaticallyImplyLeading: false,
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => FirestoreService.markAllNotificationsRead(),
                  child: const Text(
                    '모두 읽음',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
            ],
          ),
          body: snap.connectionState == ConnectionState.waiting
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A90D9)))
              : notifications.isEmpty
                  ? const Center(
                      child: Text('알림이 없어요',
                          style: TextStyle(
                              fontSize: 20, color: Color(0xFF999999))),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: notifications.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final item = notifications[i];
                        return _NotificationCard(
                          item: item,
                          onTap: () => FirestoreService.markNotificationRead(item.id),
                        );
                      },
                    ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.isRead ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFEEF4FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                    color: const Color(0xFFE53935).withValues(alpha: 0.1),
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
                    '${item.medicineName} 복용을 하지 않으셨어요',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          item.isRead ? FontWeight.normal : FontWeight.bold,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRelativeTime(item.createdAt),
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
