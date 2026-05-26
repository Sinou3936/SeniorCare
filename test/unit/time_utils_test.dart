import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/utils/time_utils.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  });

  group('slotLabel', () {
    // 새벽: 0:00 ~ 6:59
    test('00시 → 새벽', () {
      expect(slotLabel(DateTime(2024, 1, 1, 0, 0)), '새벽');
    });
    test('06시 → 새벽', () {
      expect(slotLabel(DateTime(2024, 1, 1, 6, 59)), '새벽');
    });
    // 아침: 7:00 ~ 9:59
    test('07시 → 아침', () {
      expect(slotLabel(DateTime(2024, 1, 1, 7, 0)), '아침');
    });
    test('09시 → 아침', () {
      expect(slotLabel(DateTime(2024, 1, 1, 9, 59)), '아침');
    });
    // 점심: 10:00 ~ 16:59
    test('10시 → 점심', () {
      expect(slotLabel(DateTime(2024, 1, 1, 10, 0)), '점심');
    });
    test('16시 → 점심', () {
      expect(slotLabel(DateTime(2024, 1, 1, 16, 59)), '점심');
    });
    // 저녁: 17:00 ~ 20:29
    test('17시 → 저녁', () {
      expect(slotLabel(DateTime(2024, 1, 1, 17, 0)), '저녁');
    });
    test('20:00 → 저녁', () {
      expect(slotLabel(DateTime(2024, 1, 1, 20, 0)), '저녁');
    });
    test('20:29 → 저녁', () {
      expect(slotLabel(DateTime(2024, 1, 1, 20, 29)), '저녁');
    });
    // 취침: 20:30 ~ 23:59
    test('20:30 → 취침', () {
      expect(slotLabel(DateTime(2024, 1, 1, 20, 30)), '취침');
    });
    test('23시 → 취침', () {
      expect(slotLabel(DateTime(2024, 1, 1, 23, 0)), '취침');
    });
  });

  group('weekStart', () {
    test('월요일은 그대로 반환', () {
      final monday = DateTime(2024, 5, 6); // 실제 월요일
      expect(weekStart(monday), DateTime(2024, 5, 6));
    });
    test('수요일이면 해당 주 월요일 반환', () {
      final wednesday = DateTime(2024, 5, 8);
      expect(weekStart(wednesday), DateTime(2024, 5, 6));
    });
    test('일요일이면 해당 주 월요일 반환', () {
      final sunday = DateTime(2024, 5, 12);
      expect(weekStart(sunday), DateTime(2024, 5, 6));
    });
    test('월 경계 넘어도 올바른 월요일 반환', () {
      final friday = DateTime(2024, 6, 7); // 금요일
      expect(weekStart(friday), DateTime(2024, 6, 3)); // 월요일
    });
  });

  group('formatRelativeTime', () {
    test('30분 전', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 30));
      expect(formatRelativeTime(dt), '30분 전');
    });
    test('3시간 전', () {
      final dt = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatRelativeTime(dt), '3시간 전');
    });
    test('2일 전', () {
      final dt = DateTime.now().subtract(const Duration(days: 2));
      expect(formatRelativeTime(dt), '2일 전');
    });
    test('59분 → 분 단위', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 59));
      expect(formatRelativeTime(dt), '59분 전');
    });
    test('23시간 → 시간 단위', () {
      final dt = DateTime.now().subtract(const Duration(hours: 23));
      expect(formatRelativeTime(dt), '23시간 전');
    });
  });

  group('parseTimeToMinutes', () {
    test('08:00 → 480', () {
      expect(parseTimeToMinutes('08:00'), 480);
    });
    test('12:30 → 750', () {
      expect(parseTimeToMinutes('12:30'), 750);
    });
    test('21:00 → 1260', () {
      expect(parseTimeToMinutes('21:00'), 1260);
    });
    test('잘못된 형식 → null', () {
      expect(parseTimeToMinutes('abc'), null);
      expect(parseTimeToMinutes('8'), null);
      expect(parseTimeToMinutes(''), null);
    });
  });
}
