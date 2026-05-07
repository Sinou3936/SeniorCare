import 'package:flutter/material.dart';
import '../../models/medicine_log.dart';
import '../../widgets/weekly_calendar.dart';

// 연결된 부모 정보 (Firebase 연동 전 더미)
class _Parent {
  final String id;
  final String name;
  final List<MedicineLog> logs;
  const _Parent({required this.id, required this.name, required this.logs});
}

class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedParentIndex = 0;

  late final List<_Parent> _parents = [
    _Parent(
      id: 'p1',
      name: '어머니',
      logs: [
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
      ],
    ),
    _Parent(
      id: 'p2',
      name: '아버지',
      logs: [
        MedicineLog(
          id: 'f1', medicineId: 'fm1', medicineName: '고지혈증약',
          scheduledTime: DateTime.now().copyWith(hour: 8, minute: 0, second: 0),
          taken: true, takenAt: DateTime.now().copyWith(hour: 8, minute: 30),
        ),
        MedicineLog(
          id: 'f2', medicineId: 'fm2', medicineName: '심장약',
          scheduledTime: DateTime.now().copyWith(hour: 8, minute: 0, second: 0),
          taken: true, takenAt: DateTime.now().copyWith(hour: 8, minute: 31),
        ),
        MedicineLog(
          id: 'f3', medicineId: 'fm3', medicineName: '혈압약',
          scheduledTime: DateTime.now().copyWith(hour: 21, minute: 0, second: 0),
          taken: false,
        ),
      ],
    ),
  ];

  _Parent get _currentParent => _parents[_selectedParentIndex];

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

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Map<String, List<MedicineLog>> get _grouped {
    final map = <String, List<MedicineLog>>{};
    for (final log in _currentParent.logs) {
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

  @override
  Widget build(BuildContext context) {
    final logs = _currentParent.logs;
    final takenCount = logs.where((l) => l.taken).length;
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF4A90D9),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '부모님 복용 현황',
                              style: TextStyle(color: Colors.white70, fontSize: 15),
                            ),
                            Text(
                              _currentParent.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$takenCount/${logs.length} 복용',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 부모 전환 탭 (2명 이상일 때만 표시)
                  if (_parents.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: List.generate(_parents.length, (i) {
                          final selected = i == _selectedParentIndex;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedParentIndex = i;
                                _selectedDate = DateTime.now();
                              }),
                              child: Container(
                                margin: EdgeInsets.only(right: i < _parents.length - 1 ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? Colors.white : Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    _parents[i].name,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: selected
                                          ? const Color(0xFF4A90D9)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
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
                ...grouped.entries.map((entry) => _FamilySlotGroup(
                  slot: entry.key,
                  icon: _slotIcons[entry.key]!,
                  logs: entry.value,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilySlotGroup extends StatelessWidget {
  final String slot;
  final IconData icon;
  final List<MedicineLog> logs;

  const _FamilySlotGroup({
    required this.slot,
    required this.icon,
    required this.logs,
  });

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
                Text(
                  slot,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
                ),
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
                      color: Colors.white,
                    ),
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
            child: Text(
              log.medicineName,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
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
                color: log.taken ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
