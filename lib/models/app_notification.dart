import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/time_utils.dart';

class AppNotification {
  final String id;
  final String medicineName;
  final String seniorUid;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.medicineName,
    required this.seniorUid,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      medicineName: d['medicineName'] as String? ?? '',
      seniorUid: d['seniorUid'] as String? ?? '',
      isRead: d['isRead'] as bool? ?? false,
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : kstNow(),
    );
  }
}
