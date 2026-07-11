import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/utils/medicine_schedule.dart';

void main() {
  // 등록: 2026-07-11(토) 12:30
  final start = DateTime(2026, 7, 11, 12, 30);
  DateTime day(int d) => DateTime(2026, 7, d);

  group('firstOccurrenceDate', () {
    test('시각이 이미 지났으면 다음날', () {
      // 08:00 은 12:30보다 이전 → 7/12
      expect(MedicineSchedule.firstOccurrenceDate(start, '08:00'), day(12));
    });
    test('시각이 아직이면 당일', () {
      // 19:00 은 12:30 이후 → 7/11
      expect(MedicineSchedule.firstOccurrenceDate(start, '19:00'), day(11));
    });
  });

  group('isSlotActiveOn — 1일치', () {
    test('오후(13:00): 오늘만', () {
      expect(MedicineSchedule.isSlotActiveOn(start, '13:00', 1, day(11)), isTrue);
      expect(MedicineSchedule.isSlotActiveOn(start, '13:00', 1, day(12)), isFalse);
    });
    test('오전(08:00): 지나서 내일만', () {
      expect(MedicineSchedule.isSlotActiveOn(start, '08:00', 1, day(11)), isFalse);
      expect(MedicineSchedule.isSlotActiveOn(start, '08:00', 1, day(12)), isTrue);
      expect(MedicineSchedule.isSlotActiveOn(start, '08:00', 1, day(13)), isFalse);
    });
  });

  group('isSlotActiveOn — 3일치', () {
    test('오후 13:00: 7/11,12,13 활성, 14 비활성', () {
      expect(MedicineSchedule.isSlotActiveOn(start, '13:00', 3, day(11)), isTrue);
      expect(MedicineSchedule.isSlotActiveOn(start, '13:00', 3, day(13)), isTrue);
      expect(MedicineSchedule.isSlotActiveOn(start, '13:00', 3, day(14)), isFalse);
    });
  });

  group('isSlotActiveOn — 계속(null)', () {
    test('먼 미래도 활성', () {
      expect(MedicineSchedule.isSlotActiveOn(start, '08:00', null, day(30)), isTrue);
      expect(
          MedicineSchedule.isSlotActiveOn(start, '08:00', null, DateTime(2027, 1, 1)),
          isTrue);
    });
    test('첫 발생 전날은 비활성', () {
      // 08:00 첫발생 7/12 → 7/11 은 비활성
      expect(MedicineSchedule.isSlotActiveOn(start, '08:00', null, day(11)), isFalse);
    });
  });

  group('hasActiveOnOrAfter', () {
    test('1일치 오후13시, 등록 다음날엔 종료', () {
      // 13:00 첫발생 7/11, 1일 → 마지막 7/11
      expect(MedicineSchedule.hasActiveOnOrAfter(start, ['13:00'], 1, day(11)), isTrue);
      expect(MedicineSchedule.hasActiveOnOrAfter(start, ['13:00'], 1, day(12)), isFalse);
    });
    test('계속은 항상 true', () {
      expect(
          MedicineSchedule.hasActiveOnOrAfter(start, ['08:00'], null, day(28)), isTrue);
    });
    test('여러 슬롯 중 하나라도 남으면 true', () {
      // 08:00(첫발생 7/12) 1일치 → 마지막 7/12. 7/12엔 활성.
      expect(
          MedicineSchedule.hasActiveOnOrAfter(start, ['08:00', '13:00'], 1, day(12)),
          isTrue);
    });
  });
}
