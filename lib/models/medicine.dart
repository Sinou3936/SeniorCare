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
}
