import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine.dart';
import '../models/medicine_log.dart';
import '../models/appointment.dart';
import '../models/app_notification.dart';
import '../utils/time_utils.dart';
import 'auth_service.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static const _codeExpireMinutes = 60;

  // ?€?€ ì»¬ë ‰??ì°¸ì¡° ?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€
  static CollectionReference get _users => _db.collection('users');
  static CollectionReference get _medicines =>
      _users.doc(AuthService.uid).collection('medicines');
  static CollectionReference get _logs =>
      _users.doc(AuthService.uid).collection('medicine_logs');
  static CollectionReference get _appointments =>
      _users.doc(AuthService.uid).collection('appointments');

  // ?€?€ 6?ë¦¬ ?°ê²° ì½”ë“œ ?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String _generateCode() {
    final r = Random.secure();
    return List.generate(6, (_) => _chars[r.nextInt(_chars.length)]).join();
  }

  /// ?œë‹ˆ??ì½”ë“œ ?¬ìƒ??(ê¸°ì¡´ ì½”ë“œ ?? œ ????ì½”ë“œ ë°œê¸‰)
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

  /// ?œë‹ˆ??ì½”ë“œ ê°€?¸ì˜¤ê¸?(?†ìœ¼ë©??ì„±, ë§Œë£Œ?ìœ¼ë©??¬ìƒ??
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

    // ??ì½”ë“œ ë°œê¸‰
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

  /// ê°€ì¡?ì½”ë“œ ê²€ì¦????œë‹ˆ??uid ë°˜í™˜ (?†ìœ¼ë©?null, ë§Œë£Œë©?'expired')
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

  /// ê°€ì¡? ?œë‹ˆ?´ì? ?°ê²° (?‘ë°©??ê¸°ë¡)
  static Future<void> linkToSenior(String seniorUid) async {
    final familyUid = AuthService.uid!;
    // ê°€ì¡?doc???œë‹ˆ??uid ?€??    await _users.doc(familyUid).set(
      {'linkedSeniorUid': seniorUid},
      SetOptions(merge: true),
    );
    // ?œë‹ˆ??doc??ê°€ì¡?uid ì¶”ê?
    await _users.doc(seniorUid).set(
      {'linkedFamilyUids': FieldValue.arrayUnion([familyUid])},
      SetOptions(merge: true),
    );
  }

  /// FCM ? í° ?€??(?¬ìš©??doc???€?? Cloud Functions?ì„œ ì°¸ì¡°)
  static Future<void> saveFcmToken(String token) async {
    await _users.doc(AuthService.uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  /// ê°€ì¡? ?°ê²°???œë‹ˆ??uid ì¡°íšŒ
  static Future<String?> getLinkedSeniorUid() async {
    final doc = await _users.doc(AuthService.uid).get();
    if (!doc.exists) return null;
    return (doc.data() as Map?)?['linkedSeniorUid'] as String?;
  }

  /// ?œë‹ˆ?? ?°ê²°??ë³´í˜¸??uid ëª©ë¡ ì¡°íšŒ
  static Future<List<String>> getLinkedFamilyUids() async {
    final doc = await _users.doc(AuthService.uid).get();
    if (!doc.exists) return [];
    final list = (doc.data() as Map?)?['linkedFamilyUids'];
    if (list == null) return [];
    return List<String>.from(list as List);
  }

  /// ê°€ì¡? ë³¸ì¸???œë‹ˆ?´ì? ?°ê²° ?´ì œ
  static Future<void> unlinkFromSenior() async {
    final familyUid = AuthService.uid!;
    final seniorUid = await getLinkedSeniorUid();
    // ê°€ì¡?doc?ì„œ linkedSeniorUid ?œê±°
    await _users.doc(familyUid).update({'linkedSeniorUid': FieldValue.delete()});
    // ?œë‹ˆ??doc?ì„œ ê°€ì¡?uid ?œê±°
    if (seniorUid != null) {
      await _users.doc(seniorUid).update({
        'linkedFamilyUids': FieldValue.arrayRemove([familyUid]),
      });
    }
  }

  /// ?œë‹ˆ?? ?¹ì • ë³´í˜¸?ì? ?°ê²° ?´ì œ
  static Future<void> unlinkFamily(String familyUid) async {
    final seniorUid = AuthService.uid!;
    await _users.doc(familyUid).update({'linkedSeniorUid': FieldValue.delete()});
    await _users.doc(seniorUid).update({
      'linkedFamilyUids': FieldValue.arrayRemove([familyUid]),
    });
  }

  // ?€?€ ??(Medicine) ?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€
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
          .where((m) =>
              m.endDate == null ||
              !m.endDate!.isBefore(todayDate))
          .toList();
    });
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

  // ?€?€ ë³µìš© ê¸°ë¡ (MedicineLog) ?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€

  /// ì£¼ê°„ ? ì§œë³?ë³µìš© ?íƒœ ?¤íŠ¸ë¦?(true=?„ë£Œ, false=ë¯¸ì™„ë£? null=ê¸°ë¡?†ìŒ)
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

  /// ?´ë‹¹ ? ì§œ???½ë³„ ë¡œê·¸ê°€ ?†ìœ¼ë©??ë™ ?ì„± (ê¸°ì¡´ ë¡œê·¸ê°€ ?ˆì–´???„ë½???½ë§Œ ì¶”ê?)
  static Future<void> generateLogsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final results = await Future.wait([
      _logs
          .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('scheduledTime', isLessThan: Timestamp.fromDate(end))
          .get(),
      _medicines.get(),
    ]);

    final existingSnap = results[0];
    final medicinesSnap = results[1];

    // ?´ë? ë¡œê·¸ê°€ ?ˆëŠ” ??ID ì§‘í•©
    final existingMedicineIds = existingSnap.docs
        .map((d) => (d.data() as Map<String, dynamic>)['medicineId'] as String)
        .toSet();

    final batch = _db.batch();
    bool hasNew = false;

    for (final doc in medicinesSnap.docs) {
      final medicine = Medicine.fromFirestore(doc);
      if (existingMedicineIds.contains(medicine.id)) continue;

      final startDay = DateTime(medicine.startDate.year, medicine.startDate.month, medicine.startDate.day);
      if (start.isBefore(startDay)) continue;
      if (medicine.endDate != null) {
        final endDay = DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day);
        if (start.isAfter(endDay)) continue;
      }

      for (final time in medicine.times) {
        final parts = time.split(':');
        if (parts.length != 2) continue;
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h == null || m == null) continue;
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

  /// ê°€ì¡? ?œë‹ˆ?´ì˜ ì£¼ê°„ ë³µìš© ?íƒœ ?¤íŠ¸ë¦?  static Stream<Map<DateTime, bool?>> watchSeniorWeekStatus(
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

  // ?€?€ ë³‘ì› ?ˆì•½ (Appointment) ?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€
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

  // ?€?€ ?Œë¦¼ (Notifications) ?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€?€
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

  /// ëª¨ë“  ?°ì´??ì´ˆê¸°??(medicines, medicine_logs, appointments)
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
