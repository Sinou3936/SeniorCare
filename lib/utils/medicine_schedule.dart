/// 복약 슬롯 발생일 계산 (순수 함수, 네트워크·타임존플러그인 불필요).
///
/// - [startDate] 등록 시각(기준점)
/// - [slotTime] "HH:MM"
/// - [durationDays] 복용 기간(일수). null = 계속(무한).
///
/// 규칙: 각 슬롯은 등록 시각 이후 그 시각의 첫 발생부터 N일 발동한다.
/// 등록 시점에 이미 지난 슬롯은 다음날로 롤오버된다.
class MedicineSchedule {
  static (int, int) _hm(String t) {
    final p = t.split(':');
    return (int.parse(p[0]), int.parse(p[1]));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 슬롯의 첫 발생 "날짜" (등록시각 이후 첫 hour:minute; 이미 지났으면 다음날).
  static DateTime firstOccurrenceDate(DateTime startDate, String slotTime) {
    final (h, m) = _hm(slotTime);
    var first = DateTime(startDate.year, startDate.month, startDate.day, h, m);
    if (!first.isAfter(startDate)) {
      first = first.add(const Duration(days: 1));
    }
    return _dateOnly(first);
  }

  /// 이 슬롯이 이 날짜([date])에 활성인가.
  static bool isSlotActiveOn(
      DateTime startDate, String slotTime, int? durationDays, DateTime date) {
    final first = firstOccurrenceDate(startDate, slotTime);
    final d = _dateOnly(date);
    if (d.isBefore(first)) return false;
    if (durationDays == null) return true;
    final index = d.difference(first).inDays;
    return index < durationDays;
  }

  /// [fromDate] 또는 이후에 활성 발생이 하나라도 남았으면 true.
  /// (약 목록에서 완전히 종료된 약을 숨기는 데 사용)
  static bool hasActiveOnOrAfter(
      DateTime startDate, List<String> times, int? durationDays, DateTime fromDate) {
    if (durationDays == null) return true;
    final from = _dateOnly(fromDate);
    for (final t in times) {
      final first = firstOccurrenceDate(startDate, t);
      final lastDate = first.add(Duration(days: durationDays - 1));
      if (!lastDate.isBefore(from)) return true; // 마지막 발생일이 fromDate 이후
    }
    return false;
  }
}
