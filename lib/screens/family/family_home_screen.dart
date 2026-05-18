import 'package:flutter/material.dart';
import '../../models/medicine_log.dart';
import '../../services/firestore_service.dart';
import '../../services/prefs_service.dart';
import '../../utils/time_utils.dart';
import '../../widgets/weekly_calendar.dart';

class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen> {
  DateTime _selectedDate = kstNow();
  String? _seniorUid;
  bool _loading = true;

  DateTime get _weekStart {
    final now = _selectedDate;
    return now.subtract(Duration(days: now.weekday - 1));
  }

  static const _slotOrder = ['아침', '점심', '저녁', '취침'];
  static const _slotIcons = {
    '아침': Icons.wb_sunny_outlined,
    '점심': Icons.light_mode_outlined,
    '저녁': Icons.nights_stay_outlined,
    '취침': Icons.bedtime_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadSeniorUid();
  }

  Future<void> _loadSeniorUid() async {
    final cached = await PrefsService.loadLinkedSeniorUid();
    if (cached != null) {
      if (mounted) setState(() { _seniorUid = cached; _loading = false; });
      return;
    }
    final uid = await FirestoreService.getLinkedSeniorUid();
    if (uid != null) await PrefsService.saveLinkedSeniorUid(uid);
    if (mounted) setState(() { _seniorUid = uid; _loading = false; });
  }

  String _slotLabel(DateTime dt) {
    if (dt.hour < 10) return '아침';
    if (dt.hour < 14) return '점심';
    if (dt.hour < 20) return '저녁';
    return '취침';
  }

  Map<String, List<MedicineLog>> _grouped(List<MedicineLog> logs) {
    final map = <String, List<MedicineLog>>{};
    for (final log in logs) {
      map.putIfAbsent(_slotLabel(log.scheduledTime), () => []).add(log);
    }
    return {
      for (final slot in _slotOrder)
        if (map.containsKey(slot)) slot: map[slot]!,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE8896A))),
      );
    }
    if (_seniorUid == null) {
      return const Scaffold(
        body: Center(
          child: Text('연결된 부모님이 없어요',
              style: TextStyle(fontSize: 20, color: Color(0xFF999999))),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<Map<DateTime, bool?>>(
        stream: FirestoreService.watchSeniorWeekStatus(_seniorUid!, _weekStart),
        builder: (context, weekSnap) {
          final statusMap = weekSnap.data ?? {};
          return StreamBuilder<List<MedicineLog>>(
            stream: FirestoreService.watchSeniorLogsForDate(
                _seniorUid!, _selectedDate),
            builder: (context, snap) {
              final logs = snap.data ?? [];
              final takenCount = logs.where((l) => l.taken).length;
              final grouped = _grouped(logs);

              return Column(
                children: [
                  Container(
                    color: const Color(0xFFE8896A),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('부모님 복용 현황',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 15)),
                                Text('부모님',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$takenCount/${logs.length} 복용',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  WeeklyCalendar(
                    selectedDate: _selectedDate,
                    onDateSelected: (d) => setState(() => _selectedDate = d),
                    statusMap: statusMap,
                  ),
                  Expanded(
                    child: logs.isEmpty &&
                            snap.connectionState == ConnectionState.waiting
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFE8896A)))
                        : logs.isEmpty
                            ? const Center(
                                child: Text('복용 기록이 없어요',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF999999))),
                              )
                            : ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  const Text(
                                    '오늘 복용 현황',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A2E)),
                                  ),
                                  const SizedBox(height: 12),
                                  ...grouped.entries.map(
                                      (entry) => _FamilySlotGroup(
                                            slot: entry.key,
                                            icon: _slotIcons[entry.key]!,
                                            logs: entry.value,
                                          )),
                                ],
                              ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _FamilySlotGroup extends StatelessWidget {
  final String slot;
  final IconData icon;
  final List<MedicineLog> logs;

  const _FamilySlotGroup({required this.slot, required this.icon, required this.logs});

  @override
  Widget build(BuildContext context) {
    final takenCount = logs.where((l) => l.taken).length;
    final allTaken = takenCount == logs.length;
    final noneTaken = takenCount == 0;
    final dt = logs.first.scheduledTime;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final statusColor = allTaken
        ? const Color(0xFF4CAF50)
        : noneTaken
            ? const Color(0xFFE53935)
            : const Color(0xFFFF9800);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 26, color: statusColor),
                const SizedBox(width: 10),
                Text(slot,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(width: 8),
                Text(timeStr,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF999999))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    allTaken
                        ? '모두 복용'
                        : noneTaken
                            ? '미복용'
                            : '$takenCount/${logs.length} 복용',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          ...logs.map((log) => _FamilyMedicineRow(log: log)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FamilyMedicineRow extends StatelessWidget {
  final MedicineLog log;
  const _FamilyMedicineRow({required this.log});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: log.taken
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                  : const Color(0xFFE53935).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              log.taken ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 24,
              color: log.taken ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(log.medicineName,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: log.taken
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                  : const Color(0xFFE53935).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              log.taken ? '완료' : '미복용',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color:
                      log.taken ? const Color(0xFF4CAF50) : const Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }
}
