import 'package:flutter/material.dart';
import '../../models/medicine_log.dart';
import '../../widgets/weekly_calendar.dart';
import 'senior_my_code_screen.dart';

class SeniorHomeScreen extends StatefulWidget {
  const SeniorHomeScreen({super.key});

  @override
  State<SeniorHomeScreen> createState() => _SeniorHomeScreenState();
}

class _SeniorHomeScreenState extends State<SeniorHomeScreen> {
  DateTime _selectedDate = DateTime.now();

  final List<MedicineLog> _logs = [
    MedicineLog(
      id: '1', medicineId: 'm1', medicineName: '혈압약',
      scheduledTime: DateTime.now().copyWith(hour: 8, minute: 0, second: 0),
      taken: true, takenAt: DateTime.now().copyWith(hour: 8, minute: 12),
    ),
    MedicineLog(
      id: '2', medicineId: 'm2', medicineName: '당뇨약',
      scheduledTime: DateTime.now().copyWith(hour: 8, minute: 0, second: 0),
      taken: false,
    ),
    MedicineLog(
      id: '3', medicineId: 'm3', medicineName: '비타민',
      scheduledTime: DateTime.now().copyWith(hour: 8, minute: 0, second: 0),
      taken: false,
    ),
    MedicineLog(
      id: '4', medicineId: 'm4', medicineName: '관절약',
      scheduledTime: DateTime.now().copyWith(hour: 8, minute: 0, second: 0),
      taken: false,
    ),
    MedicineLog(
      id: '5', medicineId: 'm2', medicineName: '당뇨약',
      scheduledTime: DateTime.now().copyWith(hour: 12, minute: 0, second: 0),
      taken: false,
    ),
    MedicineLog(
      id: '6', medicineId: 'm1', medicineName: '혈압약',
      scheduledTime: DateTime.now().copyWith(hour: 18, minute: 0, second: 0),
      taken: false,
    ),
    MedicineLog(
      id: '7', medicineId: 'm3', medicineName: '비타민',
      scheduledTime: DateTime.now().copyWith(hour: 21, minute: 0, second: 0),
      taken: false,
    ),
  ];

  static const _slotOrder = ['아침', '점심', '저녁', '취침'];

  static const _slotIcons = {
    '아침': Icons.wb_sunny_outlined,
    '점심': Icons.light_mode_outlined,
    '저녁': Icons.nights_stay_outlined,
    '취침': Icons.bedtime_outlined,
  };

  String _slotLabel(DateTime dt) {
    if (dt.hour < 10) return '아침';
    if (dt.hour < 14) return '점심';
    if (dt.hour < 20) return '저녁';
    return '취침';
  }

  String _weekdayStr(int wd) => ['월', '화', '수', '목', '금', '토', '일'][wd - 1];

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Map<String, List<MedicineLog>> get _grouped {
    final map = <String, List<MedicineLog>>{};
    for (final log in _logs) {
      map.putIfAbsent(_slotLabel(log.scheduledTime), () => []).add(log);
    }
    return {
      for (final slot in _slotOrder)
        if (map.containsKey(slot)) slot: map[slot]!,
    };
  }

  Map<DateTime, bool?> get _statusMap {
    final today = _dateOnly(DateTime.now());
    return {
      today: false,
      today.subtract(const Duration(days: 1)): true,
      today.subtract(const Duration(days: 2)): true,
      today.subtract(const Duration(days: 3)): false,
    };
  }

  void _toggleTaken(String id) {
    setState(() {
      final i = _logs.indexWhere((l) => l.id == id);
      if (i == -1) return;
      final log = _logs[i];
      _logs[i] = MedicineLog(
        id: log.id,
        medicineId: log.medicineId,
        medicineName: log.medicineName,
        scheduledTime: log.scheduledTime,
        taken: !log.taken,
        takenAt: !log.taken ? DateTime.now() : null,
      );
    });
  }

  void _takeAll(List<MedicineLog> group) {
    setState(() {
      for (final log in group) {
        if (!log.taken) _toggleTaken(log.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final takenCount = _logs.where((l) => l.taken).length;
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF4A90D9),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${now.month}월 ${now.day}일 ${_weekdayStr(now.weekday)}요일',
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const Text(
                          '안녕하세요!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$takenCount/${_logs.length} 복용',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SeniorMyCodeScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.qr_code_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  '내 코드',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          WeeklyCalendar(
            selectedDate: _selectedDate,
            onDateSelected: (d) => setState(() => _selectedDate = d),
            statusMap: _statusMap,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '오늘 복용 현황',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                ...grouped.entries.map((entry) => _SlotGroup(
                  slot: entry.key,
                  icon: _slotIcons[entry.key]!,
                  logs: entry.value,
                  onToggle: _toggleTaken,
                  onTakeAll: () => _takeAll(entry.value),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotGroup extends StatelessWidget {
  final String slot;
  final IconData icon;
  final List<MedicineLog> logs;
  final ValueChanged<String> onToggle;
  final VoidCallback onTakeAll;

  const _SlotGroup({
    required this.slot,
    required this.icon,
    required this.logs,
    required this.onToggle,
    required this.onTakeAll,
  });

  @override
  Widget build(BuildContext context) {
    final takenCount = logs.where((l) => l.taken).length;
    final allTaken = takenCount == logs.length;
    final dt = logs.first.scheduledTime;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: allTaken
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.08)
                  : const Color(0xFF4A90D9).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: allTaken
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF4A90D9),
                ),
                const SizedBox(width: 10),
                Text(
                  slot,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: allTaken
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: allTaken
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF4A90D9).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$takenCount/${logs.length}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: allTaken ? Colors.white : const Color(0xFF4A90D9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 약 목록
          ...logs.map((log) => _MedicineRow(
                log: log,
                onToggle: () => onToggle(log.id),
              )),
          // 모두 복용 버튼
          if (!allTaken)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onTakeAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '모두 복용',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          if (allTaken) const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  final MedicineLog log;
  final VoidCallback onToggle;

  const _MedicineRow({required this.log, required this.onToggle});

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
                  : const Color(0xFF4A90D9).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication_rounded,
              size: 24,
              color: log.taken
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF4A90D9),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              log.medicineName,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: log.taken ? const Color(0xFF4CAF50) : Colors.white,
                border: Border.all(
                  color: log.taken
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 26,
                color: log.taken ? Colors.white : const Color(0xFFCCCCCC),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
