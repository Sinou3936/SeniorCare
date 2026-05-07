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
}
