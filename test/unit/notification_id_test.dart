import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/services/notification_service.dart';

void main() {
  group('notificationId 생성', () {
    test('같은 medicineId + 같은 인덱스 → 같은 ID', () {
      final id1 = NotificationService.notificationIdForTest('med-abc', 0);
      final id2 = NotificationService.notificationIdForTest('med-abc', 0);
      expect(id1, id2);
    });

    test('같은 medicineId, 다른 인덱스 → 다른 ID', () {
      final id0 = NotificationService.notificationIdForTest('med-abc', 0);
      final id1 = NotificationService.notificationIdForTest('med-abc', 1);
      final id2 = NotificationService.notificationIdForTest('med-abc', 2);
      final id3 = NotificationService.notificationIdForTest('med-abc', 3);

      expect({id0, id1, id2, id3}.length, 4); // 모두 고유해야 함
    });

    test('다른 medicineId → 다른 ID (충돌 없음 검증)', () {
      final ids = <int>{};
      final medicines = ['med-001', 'med-002', 'med-003', 'med-xyz', 'abc123'];
      for (final med in medicines) {
        for (int i = 0; i < 4; i++) {
          ids.add(NotificationService.notificationIdForTest(med, i));
        }
      }
      // 5개 약 × 4개 시간대 = 20개 모두 고유해야 함
      expect(ids.length, 20);
    });

    test('ID는 int 범위 내 양수', () {
      final id = NotificationService.notificationIdForTest('test-med', 0);
      expect(id, greaterThan(0));
      expect(id, lessThan(2147483647)); // int32 max
    });
  });
}
