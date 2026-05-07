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
}
