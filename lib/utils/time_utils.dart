import 'package:timezone/timezone.dart' as tz;

/// 현재 시각을 KST 기준으로 반환 (기기 timezone 설정 무관)
DateTime kstNow() => tz.TZDateTime.now(tz.getLocation('Asia/Seoul'));

/// 슬롯 라벨 (새벽/아침/점심/저녁/취침)
String slotLabel(DateTime dt) {
  final m = dt.hour * 60 + dt.minute;
  if (m < 7 * 60) return '새벽';
  if (m < 10 * 60) return '아침';
  if (m < 17 * 60) return '점심';
  if (m < 20 * 60 + 30) return '저녁';
  return '취침';
}

/// 해당 주 월요일 반환
DateTime weekStart(DateTime date) =>
    date.subtract(Duration(days: date.weekday - 1));

/// DateTime → "N분 전 / N시간 전 / N일 전"
String formatRelativeTime(DateTime dt) {
  final diff = kstNow().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
}

/// "HH:mm" → 분
int? parseTimeToMinutes(String time) {
  final parts = time.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}
