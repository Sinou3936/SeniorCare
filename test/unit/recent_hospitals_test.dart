import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/models/appointment.dart';
import 'package:seniorcare/utils/recent_hospitals.dart';

Appointment appt(String name, DateTime date) =>
    Appointment(id: '$name$date', hospitalName: name, date: date);

void main() {
  group('recentHospitals', () {
    test('예약이 없으면 빈 목록', () {
      expect(recentHospitals([]), isEmpty);
    });

    test('최신 예약일 순으로 정렬된다', () {
      final result = recentHospitals([
        appt('A내과', DateTime(2026, 9, 1, 10)),
        appt('B정형외과', DateTime(2026, 10, 1, 10)),
        appt('C안과', DateTime(2026, 9, 15, 10)),
      ]);
      expect(result.map((r) => r.name), ['B정형외과', 'C안과', 'A내과']);
    });

    test('같은 병원은 한 번만, 가장 최근 예약의 시간을 쓴다', () {
      final result = recentHospitals([
        appt('A내과', DateTime(2026, 9, 1, 9, 30)),
        appt('A내과', DateTime(2026, 10, 1, 14, 0)),
      ]);
      expect(result.length, 1);
      expect(result.first.timeMinutes, 14 * 60);
    });

    test('개수 제한(기본 4개)', () {
      final result = recentHospitals([
        for (var i = 1; i <= 6; i++) appt('병원$i', DateTime(2026, 10, i, 10)),
      ]);
      expect(result.length, 4);
      expect(result.first.name, '병원6');
    });

    test('이름이 비어 있거나 공백뿐이면 제외, 앞뒤 공백은 정리', () {
      final result = recentHospitals([
        appt('  ', DateTime(2026, 10, 3, 10)),
        appt(' A내과 ', DateTime(2026, 10, 2, 10)),
      ]);
      expect(result.map((r) => r.name), ['A내과']);
    });

    test('원본 목록은 건드리지 않는다', () {
      final input = [
        appt('A내과', DateTime(2026, 9, 1, 10)),
        appt('B안과', DateTime(2026, 10, 1, 10)),
      ];
      recentHospitals(input);
      expect(input.first.hospitalName, 'A내과');
    });
  });
}
