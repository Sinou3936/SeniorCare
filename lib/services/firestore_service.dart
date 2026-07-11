import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine.dart';
import '../models/medicine_log.dart';
import '../models/appointment.dart';
import '../models/app_notification.dart';
import '../utils/time_utils.dart';
import '../utils/medicine_schedule.dart';
import 'auth_service.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static const _codeExpireMinutes = 60;

  // ── 컬렉션 참조 ──────────────────────────────────────────
  static CollectionReference get _users => _db.collection('users');
  static CollectionReference get _medicines =>
      _users.doc(AuthService.uid).collection('medicines');
  static CollectionReference get _logs =>
      _users.doc(AuthService.uid).collection('medicine_logs');
  static CollectionReference get _appointments =>
      _users.doc(AuthService.uid).collection('appointments');

  // ── 6자리 연결 코드 ──────────────────────────────────────
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String _generateCode() {
    final r = Random.secure();
    return List.generate(6, (_) => _chars[r.nextInt(_chars.length)]).join();
  }

  /// 시니어 코드 재생성 (기존 코드 삭제 후 새 코드 발급)
  static Future<({String code, bool isExpired})> regenerateSeniorCode() async {
    final uid = AuthService.uid!;
    final doc = await _users.doc(uid).get();
    if (doc.exists) {
      final oldCode = (doc.data() as Map<String, dynamic>?)?['code'] as String?;
      if (oldCode != null) {
        await _db.collection('codes').doc(oldCode).delete();
      }
    }
    await _users.doc(uid).update({'code': FieldValue.delete()});
    return getSeniorCode();
  }

  /// 시니어 코드 가져오기 (없으면 생성, 만료됐으면 재생성)
  static Future<({String code, bool isExpired})> getSeniorCode() async {
    final uid = AuthService.uid!;
    final doc = await _users.doc(uid).get();
    final data = doc.data() as Map<String, dynamic>?;

    if (data?['code'] != null) {
      final code = data!['code'] as String;
      final codeDoc = await _db.collection('codes').doc(code).get();
      if (codeDoc.exists) {
        final codeData = codeDoc.data() as Map<String, dynamic>;
        final createdAt = (codeData['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null) {
          final isExpired = kstNow().difference(createdAt).inMinutes >=
              _codeExpireMinutes;
          return (code: code, isExpired: isExpired);
        }
      }
    }

    // 새 코드 발급
    String code;
    do {
      code = _generateCode();
      final existing = await _db.collection('codes').doc(code).get();
      if (!existing.exists) break;
    } while (true);

    await _users.doc(uid).set({'code': code}, SetOptions(merge: true));
    await _db.collection('codes').doc(code).set({
      'ownerUid': uid,
      'createdAt': Timestamp.now(),
    });
    return (code: code, isExpired: false);
  }

  /// 가족 코드 검증 → 시니어 uid 반환 (없으면 null, 만료면 'expired')
  static Future<String?> verifySeniorCode(String code) async {
    final doc =
        await _db.collection('codes').doc(code.toUpperCase()).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    if (createdAt != null) {
      final isExpired = kstNow().difference(createdAt).inMinutes >=
          _codeExpireMinutes;
      if (isExpired) return 'expired';
    }
    return data['ownerUid'] as String?;
  }

  /// 가족: 시니어와 연결 (양방향 기록)
  static Future<void> linkToSenior(String seniorUid) async {
    final familyUid = AuthService.uid!;
    // 가족 doc에 시니어 uid 저장
    await _users.doc(familyUid).set(
      {'linkedSeniorUid': seniorUid},
      SetOptions(merge: true),
    );
    // 시니어 doc에 가족 uid 추가
    await _users.doc(seniorUid).set(
      {'linkedFamilyUids': FieldValue.arrayUnion([familyUid])},
      SetOptions(merge: true),
    );
  }

  /// FCM 토큰 저장 (사용자 doc에 저장, Cloud Functions에서 참조)
  static Future<void> saveFcmToken(String token) async {
    await _users.doc(AuthService.uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  /// 가족: 미복용 알림 수신 설정 저장 (Cloud Functions가 발송 전 확인)
  static Future<void> setMissedDoseNotificationEnabled(bool enabled) async {
    await _users.doc(AuthService.uid).set(
      {'missedDoseNotificationEnabled': enabled},
      SetOptions(merge: true),
    );
  }

  /// 가족: 미복용 알림 수신 설정 조회 (기본 true)
  static Future<bool> getMissedDoseNotificationEnabled() async {
    final doc = await _users.doc(AuthService.uid).get();
    if (!doc.exists) return true;
    return (doc.data() as Map?)?['missedDoseNotificationEnabled'] as bool? ?? true;
  }

  /// 가족: 연결된 시니어 uid 조회
  static Future<String?> getLinkedSeniorUid() async {
    final doc = await _users.doc(AuthService.uid).get();
    if (!doc.exists) return null;
    return (doc.data() as Map?)?['linkedSeniorUid'] as String?;
  }

  /// 시니어: 연결된 보호자 uid 목록 조회
  static Future<List<String>> getLinkedFamilyUids() async {
    final doc = await _users.doc(AuthService.uid).get();
    if (!doc.exists) return [];
    final list = (doc.data() as Map?)?['linkedFamilyUids'];
    if (list == null) return [];
    return List<String>.from(list as List);
  }

  /// 가족: 본인이 시니어와 연결 해제
  static Future<void> unlinkFromSenior() async {
    final familyUid = AuthService.uid!;
    final seniorUid = await getLinkedSeniorUid();
    // 가족 doc에서 linkedSeniorUid 제거
    await _users.doc(familyUid).update({'linkedSeniorUid': FieldValue.delete()});
    // 시니어 doc에서 가족 uid 제거
    if (seniorUid != null) {
      await _users.doc(seniorUid).update({
        'linkedFamilyUids': FieldValue.arrayRemove([familyUid]),
      });
    }
  }

  /// 시니어: 특정 보호자와 연결 해제
  static Future<void> unlinkFamily(String familyUid) async {
    final seniorUid = AuthService.uid!;
    await _users.doc(familyUid).update({'linkedSeniorUid': FieldValue.delete()});
    await _users.doc(seniorUid).update({
      'linkedFamilyUids': FieldValue.arrayRemove([familyUid]),
    });
  }

  // ── 약 (Medicine) ────────────────────────────────────────
  static Stream<Medicine?> watchMedicine(String id) {
    return _medicines.doc(id).snapshots().map(
          (d) => d.exists ? Medicine.fromFirestore(d) : null,
        );
  }

  static Stream<List<Medicine>> watchMedicines() {
    return _medicines.orderBy('name').snapshots().map((s) {
      final today = kstNow();
      final todayDate = DateTime(today.year, today.month, today.day);
      return s.docs
          .map((d) => Medicine.fromFirestore(d))
          .where((m) => MedicineSchedule.hasActiveOnOrAfter(
              m.startDate, m.times, m.durationDays, todayDate))
          .toList();
    });
  }

  static Future<List<Medicine>> getActiveMedicines() async {
    final snap = await _medicines.get();
    final today = kstNow();
    final todayDate = DateTime(today.year, today.month, today.day);
    return snap.docs
        .map((d) => Medicine.fromFirestore(d))
        .where((m) => MedicineSchedule.hasActiveOnOrAfter(
            m.startDate, m.times, m.durationDays, todayDate))
        .toList();
  }

  static Future<void> addMedicine(Medicine m) async {
    await _medicines.doc(m.id).set(m.toMap());
  }

  static Future<void> updateMedicine(Medicine m) async {
    await _medicines.doc(m.id).update(m.toMap());

    final allLogs = await _logs.where('medicineId', isEqualTo: m.id).get();
    if (allLogs.docs.isNotEmpty) {
      final today = kstNow();
      final todayStart = DateTime(today.year, today.month, today.day);

      final batch = _db.batch();
      for (final doc in allLogs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final taken = data['taken'] as bool? ?? false;
        final scheduled = (data['scheduledTime'] as Timestamp).toDate();
        final isPast = scheduled.isBefore(todayStart); // 오늘 이전 = 과거

        if (isPast) {
          // 과거 로그: 이름만 업데이트 (복용 기록 유지)
          batch.update(doc.reference, {'medicineName': m.name});
        } else {
          // 오늘 및 미래: 미복용이면 삭제(시간 변경 반영), 복용 완료면 이름만 업데이트
          if (!taken) {
            batch.delete(doc.reference);
          } else {
            batch.update(doc.reference, {'medicineName': m.name});
          }
        }
      }
      await batch.commit();
    }

    await generateLogsForDate(kstNow());
    // 미래 날짜 로그는 해당 날짜 접근 시 generateLogsForDate()로 자동 재생성됨
  }

  static Future<void> deleteMedicine(String id) async {
    await _medicines.doc(id).delete();
    final logs = await _logs.where('medicineId', isEqualTo: id).get();
    for (final doc in logs.docs) {
      await doc.reference.delete();
    }
  }

  // ── 복용 기록 (MedicineLog) ──────────────────────────────

  /// 주간 날짜별 복용 상태 스트림 (true=완료, false=미완료, null=기록없음)
  static Stream<Map<DateTime, bool?>> watchWeekStatus(DateTime weekStart) {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    return _logs
        .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledTime', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduledTime')
        .snapshots()
        .map((s) {
      final logs = s.docs.map((d) => MedicineLog.fromFirestore(d)).toList();
      final map = <DateTime, bool?>{};
      for (final log in logs) {
        final date = DateTime(
          log.scheduledTime.year,
          log.scheduledTime.month,
          log.scheduledTime.day,
        );
        if (!map.containsKey(date)) {
          map[date] = log.taken;
        } else if (map[date] == true && !log.taken) {
          map[date] = false;
        }
      }
      return map;
    });
  }

  /// 해당 날짜에 약별 로그가 없으면 자동 생성 (오늘·미래만, 누락된 슬롯만 추가)
  /// 과거 날짜는 "실제 기록"이라 현재 스케줄로 재생성하지 않음 (중복 누적 방지)
  static Future<void> generateLogsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    // 과거 날짜는 로그 생성 스킵 — 지난 기록은 그대로 보존
    final now = kstNow();
    final todayStart = DateTime(now.year, now.month, now.day);
    if (start.isBefore(todayStart)) return;

    final results = await Future.wait([
      _logs
          .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('scheduledTime', isLessThan: Timestamp.fromDate(end))
          .get(),
      _medicines.get(),
    ]);

    final existingSnap = results[0];
    final medicinesSnap = results[1];

    // 이미 로그가 있는 (약 ID + 시각) 조합 집합 — 슬롯 단위로 누락 판별
    final existingKeys = existingSnap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      final mid = data['medicineId'] as String;
      final st = (data['scheduledTime'] as Timestamp).toDate();
      final hh = st.hour.toString().padLeft(2, '0');
      final mm = st.minute.toString().padLeft(2, '0');
      return '$mid|$hh:$mm';
    }).toSet();

    final batch = _db.batch();
    bool hasNew = false;

    for (final doc in medicinesSnap.docs) {
      final medicine = Medicine.fromFirestore(doc);

      for (final time in medicine.times) {
        // 이 슬롯이 이 날짜에 활성(발생일)인지 — durationDays 규칙
        if (!MedicineSchedule.isSlotActiveOn(
            medicine.startDate, time, medicine.durationDays, start)) {
          continue;
        }
        final parts = time.split(':');
        if (parts.length != 2) continue;
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h == null || m == null) continue;

        // 이 약의 이 시간 슬롯 로그가 이미 있으면 건너뜀 (약 단위가 아닌 슬롯 단위)
        final key = '${medicine.id}|${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        if (existingKeys.contains(key)) continue;

        final scheduled = DateTime(start.year, start.month, start.day, h, m);
        final logRef = _logs.doc();
        batch.set(logRef, MedicineLog(
          id: logRef.id,
          medicineId: medicine.id,
          medicineName: medicine.name,
          scheduledTime: scheduled,
          taken: false,
        ).toMap());
        hasNew = true;
      }
    }
    if (hasNew) await batch.commit();
  }

  static Stream<List<MedicineLog>> watchLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _logs
        .where('scheduledTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledTime', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduledTime')
        .snapshots()
        .map((s) => s.docs.map((d) => MedicineLog.fromFirestore(d)).toList());
  }

  /// 가족: 시니어의 주간 복용 상태 스트림
  static Stream<Map<DateTime, bool?>> watchSeniorWeekStatus(
      String seniorUid, DateTime weekStart) {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    return _users
        .doc(seniorUid)
        .collection('medicine_logs')
        .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledTime', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduledTime')
        .snapshots()
        .map((s) {
      final logs = s.docs.map((d) => MedicineLog.fromFirestore(d)).toList();
      final map = <DateTime, bool?>{};
      for (final log in logs) {
        final date = DateTime(
          log.scheduledTime.year,
          log.scheduledTime.month,
          log.scheduledTime.day,
        );
        if (!map.containsKey(date)) {
          map[date] = log.taken;
        } else if (map[date] == true && !log.taken) {
          map[date] = false;
        }
      }
      return map;
    });
  }

  static Stream<List<MedicineLog>> watchSeniorLogsForDate(
      String seniorUid, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _users
        .doc(seniorUid)
        .collection('medicine_logs')
        .where('scheduledTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledTime', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduledTime')
        .snapshots()
        .map((s) => s.docs.map((d) => MedicineLog.fromFirestore(d)).toList());
  }

  static Future<void> setLogTaken(String logId, bool taken) async {
    // 서버 응답을 기다리지 않음 — 오프라인서도 로컬 캐시에 즉시 반영(리스너 갱신)되고
    // 온라인 되면 자동 동기화. (await하면 오프라인서 멈춰 '모두 복용' 루프가 첫 항목에서 끊김)
    unawaited(_logs.doc(logId).update({
      'taken': taken,
      'takenAt': taken ? Timestamp.now() : null,
    }));
  }

  /// 풀스크린 알람 "복용 완료" 처리 — 오늘 해당 시간대("HH:mm") 미복용 로그 전부 taken:true
  static Future<void> markDoseTakenAt(String time) async {
    final parts = time.split(':');
    if (parts.length != 2) return;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return;

    final now = kstNow();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    // 캐시에서 읽음 — 오프라인서 기본 .get()이 서버 응답 기다리며 멈추는 것 방지
    // (오늘 로그는 generateLogsForDate로 로컬 생성·캐시돼 있음). 풀스크린 알람은
    // 오프라인서도 복용완료가 즉시 처리돼야 하므로 필수. 캐시 없으면 예외→안전 반환.
    final QuerySnapshot snap;
    try {
      snap = await _logs
          .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('scheduledTime', isLessThan: Timestamp.fromDate(end))
          .get(const GetOptions(source: Source.cache));
    } catch (_) {
      return; // 캐시 미스 등 — 화면은 정상 닫히도록 그냥 반환
    }

    final batch = _db.batch();
    bool hasUpdate = false;
    for (final doc in snap.docs) {
      final log = MedicineLog.fromFirestore(doc);
      if (log.scheduledTime.hour == h &&
          log.scheduledTime.minute == m &&
          !log.taken) {
        batch.update(doc.reference, {'taken': true, 'takenAt': Timestamp.now()});
        hasUpdate = true;
      }
    }
    // 커밋은 서버 응답 안 기다림 — 로컬 즉시 반영 + 온라인 시 동기화 (await하면 멈춤)
    if (hasUpdate) unawaited(batch.commit());
  }

  static Future<void> addLog(MedicineLog log) async {
    await _logs.doc(log.id).set(log.toMap());
  }

  // ── 병원 예약 (Appointment) ──────────────────────────────
  static Stream<List<Appointment>> watchSeniorAppointments(String seniorUid) {
    return _users
        .doc(seniorUid)
        .collection('appointments')
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs.map((d) => Appointment.fromFirestore(d)).toList());
  }

  static Stream<List<Appointment>> watchAppointments() {
    return _appointments.orderBy('date').snapshots().map(
          (s) => s.docs.map((d) => Appointment.fromFirestore(d)).toList(),
        );
  }

  /// 앱 재시작 시 알람 재등록용 — 현재 이후 예약만 반환
  static Future<List<Appointment>> getUpcomingAppointments() async {
    final snap = await _appointments
        .where('date', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .get();
    return snap.docs.map((d) => Appointment.fromFirestore(d)).toList();
  }

  static Future<void> addAppointment(Appointment a) async {
    await _appointments.doc(a.id).set(a.toMap());
  }

  static Future<void> updateAppointment(Appointment a) async {
    await _appointments.doc(a.id).update(a.toMap());
  }

  static Future<void> deleteAppointment(String id) async {
    await _appointments.doc(id).delete();
  }

  // ── 알림 (Notifications) ────────────────────────────────────
  static CollectionReference get _notifications =>
      _users.doc(AuthService.uid).collection('notifications');

  static Stream<List<AppNotification>> watchNotifications() {
    return _notifications
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AppNotification.fromFirestore(d)).toList());
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  static Future<void> markAllNotificationsRead() async {
    final snap = await _notifications.where('isRead', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// 모든 데이터 초기화 (medicines, medicine_logs, appointments)
  static Future<void> clearAllData() async {
    final futures = await Future.wait([
      _medicines.get(),
      _logs.get(),
      _appointments.get(),
    ]);
    final batch = _db.batch();
    for (final snap in futures) {
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }
}
