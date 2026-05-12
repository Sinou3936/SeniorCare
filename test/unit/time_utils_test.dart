import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/utils/time_utils.dart';

void main() {
  group('slotLabel', () {
    test('06시 → 아침', () {
      expect(slotLabel(DateTime(2024, 1, 1, 6, 0)), '아침');
    });
    test('09시 → 아침', () {
      expect(slotLabel(DateTime(2024, 1, 1, 9, 59)), '아침');
    });
    test('10시 → 점심', () {
      expect(slotLabel(DateTime(2024, 1, 1, 10, 0)), '점심');
    });
    test('13시 → 점심', () {
      expect(slotLabel(DateTime(2024, 1, 1, 13, 59)), '점심');
    });
    test('14시 → 저녁', () {
      expect(slotLabel(DateTime(2024, 1, 1, 14, 0)), '저녁');
    });
    test('19시 → 저녁', () {
      expect(slotLabel(DateTime(2024, 1, 1, 19, 59)), '저녁');
    });
    test('20시 → 취침', () {
      expect(slotLabel(DateTime(2024, 1, 1, 20, 0)), '취침');
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
