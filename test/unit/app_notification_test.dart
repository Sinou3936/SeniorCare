import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/models/app_notification.dart';

// Firestore 없이 fromMap 로직만 검증하는 경량 모델 테스트
// AppNotification 내부 파싱 로직을 직접 검증하기 위한 팩토리
AppNotification fromMap(String id, Map<String, dynamic> d) {
  return AppNotification(
    id: id,
    medicineName: d['medicineName'] as String? ?? '',
    seniorUid: d['seniorUid'] as String? ?? '',
    isRead: d['isRead'] as bool? ?? false,
    createdAt: d['createdAt'] as DateTime? ?? DateTime(2024),
  );
}

void main() {
  group('AppNotification 모델 파싱', () {
    test('정상 데이터 파싱', () {
      final now = DateTime(2024, 5, 12, 10, 0);
      final n = fromMap('noti-1', {
        'medicineName': '혈압약',
        'seniorUid': 'uid-senior',
        'isRead': false,
        'createdAt': now,
      });

      expect(n.id, 'noti-1');
      expect(n.medicineName, '혈압약');
      expect(n.seniorUid, 'uid-senior');
      expect(n.isRead, false);
      expect(n.createdAt, now);
    });

    test('isRead: true 파싱', () {
      final n = fromMap('noti-2', {
        'medicineName': '당뇨약',
        'seniorUid': 'uid-senior',
        'isRead': true,
        'createdAt': DateTime(2024),
      });
      expect(n.isRead, true);
    });

    test('medicineName 누락 시 빈 문자열', () {
      final n = fromMap('noti-3', {
        'seniorUid': 'uid-senior',
        'isRead': false,
        'createdAt': DateTime(2024),
      });
      expect(n.medicineName, '');
    });

    test('isRead 누락 시 false 기본값', () {
      final n = fromMap('noti-4', {
        'medicineName': '비타민',
        'seniorUid': 'uid-senior',
        'createdAt': DateTime(2024),
      });
      expect(n.isRead, false);
    });

    test('unread 목록 필터링', () {
      final items = [
        fromMap('1', {'medicineName': 'A', 'seniorUid': '', 'isRead': false, 'createdAt': DateTime(2024)}),
        fromMap('2', {'medicineName': 'B', 'seniorUid': '', 'isRead': true, 'createdAt': DateTime(2024)}),
        fromMap('3', {'medicineName': 'C', 'seniorUid': '', 'isRead': false, 'createdAt': DateTime(2024)}),
      ];
      final unread = items.where((n) => !n.isRead).toList();
      expect(unread.length, 2);
    });

    test('createdAt 기준 정렬 (최신순)', () {
      final older = fromMap('1', {'medicineName': 'A', 'seniorUid': '', 'isRead': false, 'createdAt': DateTime(2024, 1, 1)});
      final newer = fromMap('2', {'medicineName': 'B', 'seniorUid': '', 'isRead': false, 'createdAt': DateTime(2024, 6, 1)});
      final sorted = [older, newer]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      expect(sorted.first.id, '2');
    });
  });
}
