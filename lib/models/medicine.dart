import 'package:cloud_firestore/cloud_firestore.dart';

/// 약 종류
/// - oral  : 먹는 약 (알약, 가루약, 시럽) → "드실 시간이에요!"
/// - topical: 바르는/뿌리는 약 (안약, 연고, 흡입기) → "바르실 시간이에요!"
enum MedicineType {
  oral,
  topical;

  String get label => this == oral ? '먹는약' : '바르는약';

  String get notifyVerb => this == oral ? '드실' : '바르실';

  static MedicineType fromString(String? value) =>
      value == 'topical' ? topical : oral;
}

class Medicine {
  final String id;
  final String name;
  final String? photoUrl;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final MedicineType type;

  const Medicine({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.times,
    required this.startDate,
    this.endDate,
    this.type = MedicineType.oral,
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
      type: MedicineType.fromString(d['type'] as String?),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'photoUrl': photoUrl,
        'times': times,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'type': type.name,
      };
}
