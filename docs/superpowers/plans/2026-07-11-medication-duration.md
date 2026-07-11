# 복약 기간(duration) 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 복약 종료를 "달력 종료일"이 아닌 "복용 기간(일수)"으로 관리하고, 각 슬롯이 정확히 N회 발동(지난 슬롯은 다음날 롤오버)하도록 알람·로그를 슬롯 발생일 기준으로 재설계한다.

**Architecture:** 순수 함수 `isSlotActiveOn(medicine, slotTime, date)` 하나를 단일 소스로, (1) 알람 스케줄(앞으로 7일 윈도우, 날짜별) 과 (2) 로그 생성이 이를 공유한다. 스케줄한 알람 ID를 prefs에 저장해 재등록 시 전부 취소(고아 방지). 무한(계속)약은 `durationDays==null`.

**Tech Stack:** Flutter, flutter_local_notifications(zonedSchedule), cloud_firestore(offline persistence), shared_preferences, timezone. 기존 테스트: `flutter test`.

스펙: `docs/superpowers/specs/2026-07-11-medication-duration-design.md`

---

## 파일 구조

- `lib/models/medicine.dart` — `endDate`(DateTime?) → `durationDays`(int?) 필드 교체
- `lib/utils/medicine_schedule.dart` **(신규)** — 순수 로직: `firstOccurrenceDate`, `isSlotActiveOn`, `slotOccurrencesInWindow`. 테스트 대상 핵심.
- `lib/services/notification_service.dart` — `_scheduleSlotAlarms` 재작성(윈도우/날짜별), 윈도우 ID, prefs 기반 취소
- `lib/services/prefs_service.dart` — 스케줄된 알람 ID 집합 저장/로드 추가
- `lib/services/firestore_service.dart` — `generateLogsForDate` 활성판정 교체, `watchMedicines`/`getActiveMedicines` 필터 교체
- `lib/screens/senior/senior_medicine_add_screen.dart` — 기간 입력 UI(프리셋+스테퍼)
- `lib/screens/senior/senior_medicine_edit_screen.dart` — 동일
- `lib/screens/senior/senior_medicine_detail_screen.dart` — 표시 문구
- `lib/screens/senior/medicine_alarm_screen.dart` — 복용완료 시 윈도우 재연장 호출
- `test/medicine_schedule_test.dart` **(신규)** — 순수 로직 단위 테스트
- `pubspec.yaml` — 1.1.0

---

## Task 1: Medicine 모델 — durationDays 필드 교체

**Files:**
- Modify: `lib/models/medicine.dart`
- Test: `test/medicine_model_test.dart` (신규)

- [ ] **Step 1: 실패 테스트 작성**

`test/medicine_model_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/models/medicine.dart';

void main() {
  test('durationDays 왕복 직렬화', () {
    final m = Medicine(
      id: 'x', name: '약',
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
      id: 'x', name: '약', times: const ['08:00'],
      startDate: DateTime(2026, 7, 11), durationDays: null,
    );
    expect(m.toMap()['durationDays'], isNull);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/medicine_model_test.dart`
Expected: 컴파일 실패 (`durationDays` 파라미터 없음)

- [ ] **Step 3: 모델 수정**

`lib/models/medicine.dart` — `endDate` 관련 3곳을 `durationDays`로 교체:
```dart
// 필드 (line 24)
final int? durationDays;

// 생성자 (line 33)
this.durationDays,

// fromFirestore (line 45-47)
durationDays: (d['durationDays'] as num?)?.toInt(),

// toMap (line 57)
'durationDays': durationDays,
```
`endDate` 필드/직렬화 완전 제거.

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/medicine_model_test.dart`
Expected: PASS. (다른 파일 컴파일 에러는 후속 Task에서 해소 — 이 시점엔 앱 전체 빌드 아직 깨짐)

- [ ] **Step 5: 커밋**

```bash
git add lib/models/medicine.dart test/medicine_model_test.dart
git commit -m "feat(model): Medicine.endDate → durationDays"
```

---

## Task 2: 순수 스케줄 로직 (핵심) — isSlotActiveOn

**Files:**
- Create: `lib/utils/medicine_schedule.dart`
- Test: `test/medicine_schedule_test.dart`

- [ ] **Step 1: 실패 테스트 작성**

`test/medicine_schedule_test.dart`:
```dart
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
      expect(MedicineSchedule.isSlotActiveOn(start, '08:00', null, DateTime(2027, 1, 1)), isTrue);
    });
    test('첫 발생 전날은 비활성', () {
      // 08:00 첫발생 7/12 → 7/11 은 비활성
      expect(MedicineSchedule.isSlotActiveOn(start, '08:00', null, day(11)), isFalse);
    });
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/medicine_schedule_test.dart`
Expected: FAIL (`medicine_schedule.dart` 없음)

- [ ] **Step 3: 구현**

`lib/utils/medicine_schedule.dart`:
```dart
/// 복약 슬롯 발생일 계산 (순수 함수, 네트워크·타임존플러그인 불필요).
/// startDate = 등록 시각(기준점). slotTime = "HH:MM". durationDays null = 계속.
class MedicineSchedule {
  static (int, int) _hm(String t) {
    final p = t.split(':');
    return (int.parse(p[0]), int.parse(p[1]));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 슬롯의 첫 발생 "날짜" (등록시각 이후 첫 hour:minute; 이미 지났으면 다음날)
  static DateTime firstOccurrenceDate(DateTime startDate, String slotTime) {
    final (h, m) = _hm(slotTime);
    var first = DateTime(startDate.year, startDate.month, startDate.day, h, m);
    if (!first.isAfter(startDate)) {
      first = first.add(const Duration(days: 1));
    }
    return _dateOnly(first);
  }

  /// 이 슬롯이 이 날짜(date)에 활성인가.
  static bool isSlotActiveOn(
      DateTime startDate, String slotTime, int? durationDays, DateTime date) {
    final first = firstOccurrenceDate(startDate, slotTime);
    final d = _dateOnly(date);
    if (d.isBefore(first)) return false;
    if (durationDays == null) return true;
    final index = d.difference(first).inDays;
    return index < durationDays;
  }
}
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/medicine_schedule_test.dart`
Expected: PASS (모든 케이스)

- [ ] **Step 5: 커밋**

```bash
git add lib/utils/medicine_schedule.dart test/medicine_schedule_test.dart
git commit -m "feat(schedule): 슬롯 발생일 판정 순수 로직 + 테스트"
```

---

## Task 3: 스케줄된 알람 ID 저장 (prefs)

**Files:**
- Modify: `lib/services/prefs_service.dart`

- [ ] **Step 1: 메서드 추가**

`prefs_service.dart`에 스케줄된 윈도우 알람 ID 집합 저장/로드:
```dart
static const _kScheduledAlarmIds = 'scheduled_alarm_ids';

static Future<void> saveScheduledAlarmIds(List<int> ids) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(_kScheduledAlarmIds, ids.map((e) => e.toString()).toList());
}

static Future<List<int>> loadScheduledAlarmIds() async {
  final p = await SharedPreferences.getInstance();
  return (p.getStringList(_kScheduledAlarmIds) ?? const [])
      .map(int.parse).toList();
}
```
(기존 SharedPreferences import/패턴 따를 것.)

- [ ] **Step 2: 컴파일 확인**

Run: `flutter analyze lib/services/prefs_service.dart`
Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add lib/services/prefs_service.dart
git commit -m "feat(prefs): 스케줄된 알람 ID 집합 저장/로드"
```

---

## Task 4: 알람 스케줄 재작성 — 7일 윈도우 날짜별

**Files:**
- Modify: `lib/services/notification_service.dart` (`_scheduleSlotAlarms` 169-216, `cancelAllSlotAlarms` 248-257, `rescheduleAllAlarms` 162-167)

- [ ] **Step 1: 윈도우 ID 헬퍼 추가**

`notification_service.dart` (슬롯 ID 근처):
```dart
static const int _windowDays = 7;
static const int _epochBase = 20000; // 2020-01-01 기준 일수 오프셋 축소용

static int _dayCode(DateTime date) =>
    DateTime(date.year, date.month, date.day)
        .difference(DateTime(2020, 1, 1)).inDays; // 2026≈2380

static int _timeCode(String time) {
  final p = time.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]); // 0..1439
}

// 윈도우 메인 알람 ID: 1억대, int32 안전
static int _windowedSlotId(DateTime date, String time) =>
    100000000 + _dayCode(date) * 2000 + _timeCode(time);

// 윈도우 리마인더 ID: 2억대
static int _windowedReminderId(DateTime date, String time) =>
    200000000 + _dayCode(date) * 2000 + _timeCode(time);
```

- [ ] **Step 2: `_scheduleSlotAlarms` 재작성**

기존 169-216 전체를 아래로 교체. 스케줄한 ID를 모아 prefs에 저장(취소용).
```dart
static Future<void> _scheduleSlotAlarms(List<Medicine> medicines) async {
  final now = tz.TZDateTime.now(tz.local);
  final today = DateTime(now.year, now.month, now.day);

  // (날짜, 슬롯시각) → 활성 약 목록
  final scheduledIds = <int>[];

  for (var i = 0; i < _windowDays; i++) {
    final date = today.add(Duration(days: i));

    // 이 날짜에 활성인 슬롯시각별 약 묶기
    final Map<String, List<Medicine>> timeToMeds = {};
    for (final m in medicines) {
      for (final t in m.times) {
        if (MedicineSchedule.isSlotActiveOn(m.startDate, t, m.durationDays, date)) {
          timeToMeds.putIfAbsent(t, () => []).add(m);
        }
      }
    }

    for (final entry in timeToMeds.entries) {
      final time = entry.key;
      final meds = entry.value;
      final parts = time.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final scheduledTime = tz.TZDateTime(
          tz.local, date.year, date.month, date.day, hour, minute);
      if (!scheduledTime.isAfter(now)) continue; // 과거(오늘 지난 슬롯) 스킵

      final names = meds.map((m) => m.name).toList();
      final timeLabel = _koreanTimeLabel(hour, minute);
      final allTopical = meds.every((m) => m.type == MedicineType.topical);
      final verb = allTopical ? '바르실' : '드실';
      final verbPast = allTopical ? '바르셨어요' : '드셨어요';

      // 메인 알람 (fullScreenIntent + 채널음)
      final slotId = _windowedSlotId(date, time);
      await _local.zonedSchedule(
        id: slotId,
        title: '$timeLabel 약 $verb 시간이에요',
        body: names.join(', '),
        scheduledDate: scheduledTime,
        notificationDetails: _alarmNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: time,
      );
      scheduledIds.add(slotId);

      // +10분 리마인더
      final reminderTime = scheduledTime.add(const Duration(minutes: 10));
      final reminderId = _windowedReminderId(date, time);
      await _local.zonedSchedule(
        id: reminderId,
        title: '$timeLabel 약, 아직 안 $verbPast?',
        body: names.join(', '),
        scheduledDate: reminderTime,
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
      scheduledIds.add(reminderId);
    }
  }

  await PrefsService.saveScheduledAlarmIds(scheduledIds);
}
```
(`matchDateTimeComponents` 완전히 제거됨 = 무한반복 폐기.)

- [ ] **Step 3: `cancelAllSlotAlarms` 를 저장된 ID 기반으로 교체**

248-257을 교체:
```dart
static Future<void> cancelAllSlotAlarms({bool includeSnooze = true}) async {
  // 이전에 스케줄한 윈도우 알람 전부 취소 (고아 방지)
  final ids = await PrefsService.loadScheduledAlarmIds();
  for (final id in ids) {
    await _local.cancel(id: id);
  }
  // 스누즈는 슬롯시각 기반이라 캐시로 별도 취소
  if (includeSnooze) {
    final schedule = await PrefsService.loadMedicineSchedule();
    for (final time in schedule.keys) {
      await _local.cancel(id: 60000 + _slotNotificationId(time));
    }
  }
  await PrefsService.saveScheduledAlarmIds(const []);
}
```
`cancelSlotAlarm(time)`(단일, 알람화면 진입/닫기용)은 **윈도우 ID로 today 알람 취소**하도록 조정:
```dart
static Future<void> cancelSlotAlarm(String time) async {
  final now = tz.TZDateTime.now(tz.local);
  await _local.cancel(id: _windowedSlotId(DateTime(now.year, now.month, now.day), time));
}
static Future<void> cancelSlotReminder(String time) async {
  final now = tz.TZDateTime.now(tz.local);
  await _local.cancel(id: _windowedReminderId(DateTime(now.year, now.month, now.day), time));
}
```

- [ ] **Step 4: 정적 분석**

Run: `flutter analyze lib/services/notification_service.dart`
Expected: No issues (import `medicine_schedule.dart` 추가 필요).

- [ ] **Step 5: 커밋**

```bash
git add lib/services/notification_service.dart
git commit -m "feat(alarm): 무한반복 폐기 → 7일 윈도우 날짜별 스케줄 + ID기반 취소"
```

---

## Task 5: 로그 생성 활성판정 교체

**Files:**
- Modify: `lib/services/firestore_service.dart` (`generateLogsForDate` 319-324, `watchMedicines` 189-190, `getActiveMedicines` 201)

- [ ] **Step 1: `generateLogsForDate` 활성판정 교체**

319-337의 `[startDay~endDay]` 체크를 슬롯 단위 판정으로:
```dart
// 기존 startDay/endDate continue 블록 제거하고,
// 슬롯 루프 안에서 판정:
for (final time in medicine.times) {
  if (!MedicineSchedule.isSlotActiveOn(
      medicine.startDate, time, medicine.durationDays, start)) {
    continue;
  }
  // ... (기존 로그 생성 유지)
}
```
(`start`가 판정 날짜. `MedicineSchedule` import 추가.)

- [ ] **Step 2: 목록 필터 헬퍼 추가 (MedicineSchedule)**

먼저 `lib/utils/medicine_schedule.dart`에 "오늘 이후로 활성 슬롯이 남았나" 헬퍼 추가 + 테스트:
```dart
// medicine_schedule.dart 에 추가
/// 오늘(fromDate) 또는 이후에 활성 발생이 하나라도 남았으면 true.
static bool hasActiveOnOrAfter(
    DateTime startDate, List<String> times, int? durationDays, DateTime fromDate) {
  if (durationDays == null) return true;
  final from = _dateOnly(fromDate);
  for (final t in times) {
    final first = firstOccurrenceDate(startDate, t);
    final lastDate = first.add(Duration(days: durationDays - 1));
    if (!lastDate.isBefore(from)) return true; // 마지막 발생일이 오늘 이후
  }
  return false;
}
```
`test/medicine_schedule_test.dart`에 케이스 추가:
```dart
test('hasActiveOnOrAfter — 1일치 오후13시, 등록 다음날엔 종료', () {
  // 13:00 첫발생 7/11, 1일 → 마지막 7/11
  expect(MedicineSchedule.hasActiveOnOrAfter(start, ['13:00'], 1, day(11)), isTrue);
  expect(MedicineSchedule.hasActiveOnOrAfter(start, ['13:00'], 1, day(12)), isFalse);
});
test('hasActiveOnOrAfter — 계속은 항상 true', () {
  expect(MedicineSchedule.hasActiveOnOrAfter(start, ['08:00'], null, day(999 % 28 + 1)), isTrue);
});
```

그다음 `firestore_service.dart`의 `watchMedicines`(189-190)·`getActiveMedicines`(201) endDate 필터를 교체:
```dart
.where((m) => MedicineSchedule.hasActiveOnOrAfter(
    m.startDate, m.times, m.durationDays, todayDate))
```

- [ ] **Step 3: 정적 분석 + 기존 테스트**

Run: `flutter analyze lib/services/firestore_service.dart` 후 `flutter test`
Expected: analyze 통과, 기존 테스트 깨진 것들은 endDate 참조부라 이 Task로 해소.

- [ ] **Step 4: 커밋**

```bash
git add lib/services/firestore_service.dart
git commit -m "feat(logs): 로그 생성·목록 필터를 슬롯 발생일 기준으로"
```

---

## Task 6: 복용완료 시 윈도우 재연장

**Files:**
- Modify: `lib/screens/senior/medicine_alarm_screen.dart` (`_takeMedicine` 부근 76-78)

- [ ] **Step 1: 복용완료 후 재스케줄 호출**

`_takeMedicine`에서 markDoseTakenAt 후, 활성 약을 다시 불러 `rescheduleAllAlarms` 호출(윈도우 7일 앞으로 재연장):
```dart
await FirestoreService.markDoseTakenAt(widget.time);
await NotificationService.cancelSlotReminder(widget.time);
// 윈도우 재연장 (무한약 지속 보장)
final meds = await FirestoreService.getActiveMedicines();
await NotificationService.rescheduleAllAlarms(meds);
```
(오프라인 안전: getActiveMedicines가 캐시에서 읽도록 기존 패턴 유지. 무거우면 unawaited 고려.)

- [ ] **Step 2: 정적 분석**

Run: `flutter analyze lib/screens/senior/medicine_alarm_screen.dart`
Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add lib/screens/senior/medicine_alarm_screen.dart
git commit -m "feat(alarm): 복용완료 시 7일 윈도우 재연장"
```

---

## Task 7: 약 추가 화면 — 기간 프리셋 UI

**Files:**
- Modify: `lib/screens/senior/senior_medicine_add_screen.dart`

- [ ] **Step 1: 상태·위젯 교체**

`_endDate`(DateTime?) 제거 → `_durationDays`(int?, 기본 null=계속). 날짜 피커 위젯 제거 후 프리셋 버튼 행 + 직접입력 스테퍼 추가. 저장 시 `Medicine(... durationDays: _durationDays)`.

프리셋 값: `1, 3, 7, 14, null(계속)`. 선택 상태 하이라이트는 기존 슬롯 선택 스타일(코랄 #E8896A) 재사용.
```dart
int? _durationDays; // null = 계속
bool _customOpen = false;

Widget _durationSelector() {
  Widget chip(String label, int? value) {
    final selected = _durationDays == value && !_customOpen;
    return GestureDetector(
      onTap: () => setState(() { _durationDays = value; _customOpen = false; }),
      child: Container(/* 기존 슬롯 칩 스타일, selected면 코랄 */
        child: Text(label)),
    );
  }
  return Column(children: [
    Wrap(spacing: 8, children: [
      chip('1일', 1), chip('3일', 3), chip('1주일', 7),
      chip('2주일', 14), chip('계속', null),
    ]),
    GestureDetector(
      onTap: () => setState(() {
        _customOpen = true;
        _durationDays ??= 5;
      }),
      child: const Text('직접입력'),
    ),
    if (_customOpen) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(iconSize: 40, icon: const Icon(Icons.remove_circle_outline),
        onPressed: () => setState(() =>
          _durationDays = ((_durationDays ?? 1) - 1).clamp(1, 365))),
      Text('${_durationDays ?? 1} 일', style: const TextStyle(fontSize: 24)),
      IconButton(iconSize: 40, icon: const Icon(Icons.add_circle_outline),
        onPressed: () => setState(() =>
          _durationDays = ((_durationDays ?? 1) + 1).clamp(1, 365))),
    ]),
  ]);
}
```
> 실제 칩 스타일/여백은 이 화면의 기존 슬롯 선택 위젯을 복사해 맞출 것. `_slotMin/_slotMax` 등 시간 선택 부분은 유지.

- [ ] **Step 2: 빌드 확인**

Run: `flutter analyze lib/screens/senior/senior_medicine_add_screen.dart`
Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add lib/screens/senior/senior_medicine_add_screen.dart
git commit -m "feat(ui): 약 추가 — 복용 기간 프리셋+스테퍼"
```

---

## Task 8: 약 수정 화면 — 동일 UI

**Files:**
- Modify: `lib/screens/senior/senior_medicine_edit_screen.dart`

- [ ] **Step 1:** Task 7과 동일 위젯 적용. 초기값 `_durationDays = widget.medicine.durationDays`. 저장 시 `durationDays: _durationDays`. `_endDate` 참조 전부 제거.

- [ ] **Step 2:** `flutter analyze lib/screens/senior/senior_medicine_edit_screen.dart` → No issues.

- [ ] **Step 3:** 커밋 `feat(ui): 약 수정 — 복용 기간 프리셋+스테퍼`

---

## Task 9: 상세 화면 표시 문구

**Files:**
- Modify: `lib/screens/senior/senior_medicine_detail_screen.dart` (102-103 endDate 표시부)

- [ ] **Step 1:** endDate 문구를 durationDays 기준으로:
```dart
medicine.durationDays == null
    ? '복용 기간: 계속'
    : '복용 기간: ${medicine.durationDays}일',
```
(원하면 "종료 예정 M/D"도 계산해 병기 — 첫 슬롯 발생일 + (N-1)일.)

- [ ] **Step 2:** `flutter analyze` → No issues.
- [ ] **Step 3:** 커밋 `feat(ui): 상세화면 복용 기간 표시`

---

## Task 10: 버전 + 전체 검증 + 실기기 테스트

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: 버전 올림**

`pubspec.yaml` `version: 1.0.1+3` → `version: 1.1.0+4`

- [ ] **Step 2: 전체 분석·테스트**

Run: `flutter analyze` → No issues found
Run: `flutter test` → 전체 통과 (endDate 참조 잔재 없어야 함)

- [ ] **Step 3: 실기기 체크리스트** (스펙 11절)

빌드·설치 후 adb로 확인:
- 1일치 낮 등록 → 오늘 오후·저녁 + 내일 오전, 그 뒤 없음 (`adb shell dumpsys alarm | grep seniorcare` 로 origWhen 확인)
- 3일치 → 슬롯당 3회 후 멈춤
- 계속 → 앱 재실행/복용완료로 7일 유지
- 같은 시각 중복 없음 (origWhen uniq -c 전부 1)
- 오프라인(비행기모드) 등록 → 알람 정상 예약, 홈 표시 정상
- 홈 다음 주로 넘겨도 계속 약 표시

- [ ] **Step 4: 커밋**

```bash
git add pubspec.yaml
git commit -m "chore: v1.1.0 — 복약 기간 기능"
```

---

## 실행 후

`feature/medication-duration` 브랜치에서 완료 후, 실기기 검증 통과하면 main 병합/PR 결정.
```
