import 'package:flutter/material.dart';
import '../utils/time_utils.dart';

class WeeklyCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<DateTime, bool?> statusMap;

  const WeeklyCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.statusMap = const {},
  });

  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  DateTime get _weekStart {
    final wd = selectedDate.weekday;
    return selectedDate.subtract(Duration(days: wd - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final weekStart = _weekStart;
    return Container(
      color: const Color(0xFFE8896A),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final day = weekStart.add(Duration(days: i));
          final isToday = _isSameDay(day, kstNow());
          final isSelected = _isSameDay(day, selectedDate);
          final key = DateTime(day.year, day.month, day.day);
          final status = statusMap[key];

          return GestureDetector(
            onTap: () => onDateSelected(day),
            child: Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _dayLabels[i],
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFE8896A) : Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFE8896A) : Colors.white,
                      fontSize: 20,
                      fontWeight: isToday || isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: status == null
                          ? Colors.transparent
                          : status == true
                              ? const Color(0xFF4CAF50)
                              : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
