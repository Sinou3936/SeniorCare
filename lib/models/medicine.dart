import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String name;
  final String? photoUrl;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;

  const Medicine({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.times,
    required this.startDate,
    this.endDate,
  });

  factory Medicine.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Medicine(
      id: doc.id,
      name: d['name'] as String,
      photoUrl: d['photoUrl'] as String?,
      times: List<String>.from(d['times'] ?? []),
      startDate: (d['startDate'] as Timestamp).toDate(),
      endDate: d['endDate'] != null
          ? (d['endDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'photoUrl': photoUrl,
        'times': times,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      };
}
