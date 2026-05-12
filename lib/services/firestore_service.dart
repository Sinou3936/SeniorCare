import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine.dart';
import '../models/medicine_log.dart';
import '../models/appointment.dart';
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
          final isExpired = DateTime.now().difference(createdAt).inMinutes >=
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
      final isExpired = DateTime.now().difference(createdAt).inMinutes >=
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
    return _medicines.orderBy('name').snapshots().map(
          (s) => s.docs.map((d) => Medicine.fromFirestore(d)).toList(),
        );
  }

  static Future<void> addMedicine(Medicine m) async {
    await _medicines.doc(m.id).set(m.toMap());
  }

  static Future<void> updateMedicine(Medicine m) async {
    await _medicines.doc(m.id).update(m.toMap());
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
    await _logs.doc(logId).update({
      'taken': taken,
      'takenAt': taken ? Timestamp.now() : null,
    });
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

  static Future<void> addAppointment(Appointment a) async {
    await _appointments.doc(a.id).set(a.toMap());
  }

  static Future<void> updateAppointment(Appointment a) async {
    await _appointments.doc(a.id).update(a.toMap());
  }

  static Future<void> deleteAppointment(String id) async {
    await _appointments.doc(id).delete();
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
