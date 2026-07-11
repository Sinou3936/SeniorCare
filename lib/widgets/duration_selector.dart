import 'package:flutter/material.dart';

/// 복용 기간 선택 — 프리셋 버튼(1일/3일/1주일/2주일/계속) + 직접입력 ± 스테퍼.
/// [durationDays] null = 계속(무한). 시니어용 큰 버튼, 날짜 피커·키패드 없음.
class DurationSelector extends StatefulWidget {
  final int? durationDays;
  final ValueChanged<int?> onChanged;

  const DurationSelector({
    super.key,
    required this.durationDays,
    required this.onChanged,
  });

  @override
  State<DurationSelector> createState() => _DurationSelectorState();
}

class _DurationSelectorState extends State<DurationSelector> {
  static const _coral = Color(0xFFE8896A);
  static const List<int?> _presets = [1, 3, 7, 14, null];
  bool _customOpen = false;

  @override
  void initState() {
    super.initState();
    // 프리셋에 없는 값(예: 5일)이면 직접입력 모드로 시작
    _customOpen =
        widget.durationDays != null && !_presets.contains(widget.durationDays);
  }

  String _label(int? v) {
    if (v == null) return '계속';
    if (v == 7) return '1주일';
    if (v == 14) return '2주일';
    return '$v일';
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _coral.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _coral : const Color(0xFFE0E0E0),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: selected ? _coral : const Color(0xFF999999),
          ),
        ),
      ),
    );
  }

  void _step(int delta) {
    final base = widget.durationDays ?? 5;
    widget.onChanged((base + delta).clamp(1, 365));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _presets)
              _chip(
                label: _label(p),
                selected: !_customOpen && widget.durationDays == p,
                onTap: () {
                  setState(() => _customOpen = false);
                  widget.onChanged(p);
                },
              ),
            _chip(
              label: '직접입력',
              selected: _customOpen,
              onTap: () {
                setState(() => _customOpen = true);
                if (widget.durationDays == null ||
                    _presets.contains(widget.durationDays)) {
                  widget.onChanged(5);
                }
              },
            ),
          ],
        ),
        if (_customOpen)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 44,
                  color: _coral,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _step(-1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${widget.durationDays ?? 5} 일',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 44,
                  color: _coral,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _step(1),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
