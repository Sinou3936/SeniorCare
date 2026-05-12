/// 슬롯 라벨 (아침/점심/저녁/취침)
String slotLabel(DateTime dt) {
  if (dt.hour < 10) return '아침';
  if (dt.hour < 14) return '점심';
  if (dt.hour < 20) return '저녁';
  return '취침';
}

/// 해당 주 월요일 반환
DateTime weekStart(DateTime date) =>
    date.subtract(Duration(days: date.weekday - 1));

/// "HH:mm" → 분
int? parseTimeToMinutes(String time) {
  final parts = time.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}
