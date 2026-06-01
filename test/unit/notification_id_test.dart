import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/services/notification_service.dart';

void main() {
  group('슬롯 알람 ID 생성', () {
    test('같은 시간 → 같은 ID', () {
      final id1 = NotificationService.slotNotificationIdForTest('08:00');
      final id2 = NotificationService.slotNotificationIdForTest('08:00');
      expect(id1, id2);
    });

    test('다른 시간 → 다른 ID', () {
      final id1 = NotificationService.slotNotificationIdForTest('08:00');
      final id2 = NotificationService.slotNotificationIdForTest('12:00');
      final id3 = NotificationService.slotNotificationIdForTest('18:00');
      final id4 = NotificationService.slotNotificationIdForTest('21:00');
      expect({id1, id2, id3, id4}.length, 4);
    });

    test('슬롯 범위 내 모든 시간 → 고유 ID (충돌 없음)', () {
      final times = ['00:00', '04:00', '07:00', '08:00', '12:00', '18:00', '20:00', '21:00', '23:59'];
      final ids = times.map(NotificationService.slotNotificationIdForTest).toSet();
      expect(ids.length, times.length);
    });

    test('ID는 int32 범위 내 양수', () {
      final id = NotificationService.slotNotificationIdForTest('08:00');
      expect(id, greaterThan(0));
      expect(id, lessThan(2147483647));
    });
  });
}
