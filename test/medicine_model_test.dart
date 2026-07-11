import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/models/medicine.dart';

void main() {
  test('durationDays 왕복 직렬화', () {
    final m = Medicine(
      id: 'x',
      name: '약',
      times: const ['08:00'],
      startDate: DateTime(2026, 7, 11, 12, 30),
      durationDays: 3,
    );
    final map = m.toMap();
    expect(map['durationDays'], 3);
    expect(map.containsKey('endDate'), isFalse);
  });

  test('durationDays null = 계속', () {
    final m = Medicine(
      id: 'x',
      name: '약',
      times: const ['08:00'],
      startDate: DateTime(2026, 7, 11),
      durationDays: null,
    );
    expect(m.toMap()['durationDays'], isNull);
  });
}
