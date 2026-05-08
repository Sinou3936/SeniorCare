import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineLog {
  final String id;
  final String medicineId;
  final String medicineName;
  final DateTime scheduledTime;
  final bool taken;
  final DateTime? takenAt;

  const MedicineLog({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.scheduledTime,
    required this.taken,
    this.takenAt,
  });

  factory MedicineLog.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MedicineLog(
      id: doc.id,
      medicineId: d['medicineId'] as String,
      medicineName: d['medicineName'] as String,
      scheduledTime: (d['scheduledTime'] as Timestamp).toDate(),
      taken: d['taken'] as bool? ?? false,
      takenAt: d['takenAt'] != null
          ? (d['takenAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'medicineId': medicineId,
        'medicineName': medicineName,
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'taken': taken,
        'takenAt': takenAt != null ? Timestamp.fromDate(takenAt!) : null,
      };

  MedicineLog copyWith({bool? taken, DateTime? takenAt}) => MedicineLog(
        id: id,
        medicineId: medicineId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
        taken: taken ?? this.taken,
        takenAt: takenAt ?? this.takenAt,
      );
}
