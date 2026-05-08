import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine.dart';
import '../models/medicine_log.dart';
import '../models/appointment.dart';
import 'auth_service.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

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

  /// 시니어 코드 가져오기 (없으면 생성)
  static Future<String> getSeniorCode() async {
    final uid = AuthService.uid!;
    final doc = await _users.doc(uid).get();
    if (doc.exists && (doc.data() as Map)['code'] != null) {
      return (doc.data() as Map)['code'] as String;
    }
    String code;
    // 중복 없는 코드 생성
    do {
      code = _generateCode();
      final existing =
          await _db.collection('codes').doc(code).get();
      if (!existing.exists) break;
    } while (true);

    await _users.doc(uid).set({'code': code}, SetOptions(merge: true));
    await _db.collection('codes').doc(code).set({'ownerUid': uid});
    return code;
  }

  /// 가족 코드 검증 → 시니어 uid 반환 (없으면 null)
  static Future<String?> verifySeniorCode(String code) async {
    final doc =
        await _db.collection('codes').doc(code.toUpperCase()).get();
    if (!doc.exists) return null;
    return (doc.data() as Map)['ownerUid'] as String?;
  }

  /// 가족: 연결된 시니어 uid 저장
  static Future<void> linkToSenior(String seniorUid) async {
    await _users.doc(AuthService.uid).set(
      {'linkedSeniorUid': seniorUid},
      SetOptions(merge: true),
    );
  }

  /// 가족: 연결된 시니어 uid 조회
  static Future<String?> getLinkedSeniorUid() async {
    final doc = await _users.doc(AuthService.uid).get();
    if (!doc.exists) return null;
    return (doc.data() as Map?)?['linkedSeniorUid'] as String?;
  }

  // ── 약 (Medicine) ────────────────────────────────────────
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
  }

  // ── 복용 기록 (MedicineLog) ──────────────────────────────
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

  /// 가족이 특정 시니어의 로그 조회
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
}
