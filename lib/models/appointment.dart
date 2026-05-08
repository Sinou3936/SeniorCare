import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String hospitalName;
  final DateTime date;
  final String? memo;

  const Appointment({
    required this.id,
    required this.hospitalName,
    required this.date,
    this.memo,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      hospitalName: d['hospitalName'] as String,
      date: (d['date'] as Timestamp).toDate(),
      memo: d['memo'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'hospitalName': hospitalName,
        'date': Timestamp.fromDate(date),
        'memo': memo,
      };
}
