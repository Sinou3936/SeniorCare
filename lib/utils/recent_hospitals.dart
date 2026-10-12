import '../models/appointment.dart';

/// 예약 추가 화면의 "최근 병원" 버튼 한 개 — 병원 이름과 그 병원에 마지막으로 잡은 시간.
class RecentHospital {
  final String name;
  final int timeMinutes; // 하루 중 분 (10:00 = 600)

  const RecentHospital(this.name, this.timeMinutes);
}

/// 저장된 예약에서 최근 병원을 최신 예약일 순으로 [limit]개 뽑는다.
/// 같은 병원은 한 번만(가장 최근 예약 기준), 이름이 비어 있으면 제외.
List<RecentHospital> recentHospitals(List<Appointment> all, {int limit = 4}) {
  final sorted = [...all]..sort((a, b) => b.date.compareTo(a.date));
  final seen = <String>{};
  final result = <RecentHospital>[];
  for (final a in sorted) {
    final name = a.hospitalName.trim();
    if (name.isEmpty || !seen.add(name)) continue;
    result.add(RecentHospital(name, a.date.hour * 60 + a.date.minute));
    if (result.length == limit) break;
  }
  return result;
}
