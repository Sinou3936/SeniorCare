import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import 'senior_medicine_add_screen.dart' show MedicineTypeButton;

class SeniorMedicineEditScreen extends StatefulWidget {
  final Medicine medicine;
  const SeniorMedicineEditScreen({super.key, required this.medicine});

  @override
  State<SeniorMedicineEditScreen> createState() => _SeniorMedicineEditScreenState();
}

class _SeniorMedicineEditScreenState extends State<SeniorMedicineEditScreen> {
  late final TextEditingController _nameController;

  // 슬롯 이름 → 기본 분 단위
  static const _defaultMinutes = {'새벽': 4 * 60, '아침': 8 * 60, '점심': 12 * 60, '저녁': 18 * 60, '취침': 21 * 60};

  late final Map<String, int> _times;
  late final Map<String, bool> _timeEnabled;
  late DateTime? _endDate;
  late MedicineType _medicineType;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine.name);

    // 기존 times ("08:00" 형식) 파싱
    final existingTimes = <String, int>{};
    for (final t in widget.medicine.times) {
      final parts = t.split(':');
      final mins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final slot = _slotFromMinutes(mins);
      existingTimes[slot] = mins;
    }

    _times = {
      for (final e in _defaultMinutes.entries)
        e.key: existingTimes[e.key] ?? e.value,
    };
    _timeEnabled = {
      for (final slot in _defaultMinutes.keys)
        slot: existingTimes.containsKey(slot),
    };
    _endDate = widget.medicine.endDate;
    _medicineType = widget.medicine.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _slotFromMinutes(int mins) {
    if (mins < 7 * 60) return '새벽';
    if (mins < 10 * 60) return '아침';
    if (mins < 17 * 60) return '점심';
    if (mins < 20 * 60 + 30) return '저녁';
    return '취침';
  }

  String _formatTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static const _slotMin = {'새벽': 0, '아침': 7 * 60, '점심': 11 * 60 + 30, '저녁': 17 * 60 + 30, '취침': 20 * 60 + 30};
  static const _slotMax = {'새벽': 6 * 60 + 30, '아침': 9 * 60, '점심': 15 * 60, '저녁': 20 * 60, '취침': 23 * 60 + 30};

  void _adjustTime(String slot, int delta) {
    setState(() {
      final min = _slotMin[slot] ?? 0;
      final max = _slotMax[slot] ?? 23 * 60 + 59;
      _times[slot] = (_times[slot]! + delta).clamp(min, max);
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);

    final enabledTimes = _timeEnabled.entries
        .where((e) => e.value)
        .map((e) => _formatTime(_times[e.key]!))
        .toList();

    final updated = Medicine(
      id: widget.medicine.id,
      name: name,
      photoUrl: widget.medicine.photoUrl,
      times: enabledTimes,
      startDate: widget.medicine.startDate,
      endDate: _endDate,
      type: _medicineType,
    );

    await FirestoreService.updateMedicine(updated);
    await NotificationService.scheduleMedicineAlarms(
      medicineId: updated.id,
      medicineName: updated.name,
      times: enabledTimes,
      medicineType: _medicineType.name,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8896A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '약 수정',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('약 이름', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            const Text('약 종류',
                style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: MedicineTypeButton(
                    icon: Icons.medication_rounded,
                    label: '먹는약',
                    sublabel: '알약·가루약·시럽',
                    selected: _medicineType == MedicineType.oral,
                    onTap: () => setState(() => _medicineType = MedicineType.oral),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MedicineTypeButton(
                    icon: Icons.opacity_rounded,
                    label: '바르는약',
                    sublabel: '안약·연고·흡입기',
                    selected: _medicineType == MedicineType.topical,
                    onTap: () => setState(() => _medicineType = MedicineType.topical),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '복용 시간 설정',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            ..._defaultMinutes.keys.map((slot) => _TimeRow(
                  slot: slot,
                  enabled: _timeEnabled[slot]!,
                  formattedTime: _formatTime(_times[slot]!),
                  onToggle: (v) => setState(() => _timeEnabled[slot] = v),
                  onAdjust: (delta) => _adjustTime(slot, delta),
                )),
            const SizedBox(height: 24),
            const Text(
              '복용 종료일',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  locale: const Locale('ko', 'KR'),
                  initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _endDate != null ? const Color(0xFFE8896A) : const Color(0xFFE0E0E0),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: _endDate != null ? const Color(0xFFE8896A) : const Color(0xFFCCCCCC),
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _endDate != null
                            ? '${_endDate!.year}년 ${_endDate!.month}월 ${_endDate!.day}일까지'
                            : '종료일 없음 (계속 복용)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _endDate != null ? const Color(0xFF1A1A2E) : const Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                    if (_endDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _endDate = null),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF999999), size: 22),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8896A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '저장',
                        style: TextStyle(
                            fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String slot;
  final bool enabled;
  final String formattedTime;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onAdjust;

  const _TimeRow({
    required this.slot,
    required this.enabled,
    required this.formattedTime,
    required this.onToggle,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? const Color(0xFFE8896A) : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: const Color(0xFFE8896A),
              ),
              Text(
                slot,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: enabled ? const Color(0xFF1A1A2E) : const Color(0xFFCCCCCC),
                ),
              ),
            ],
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AdjBtn(label: '- 1h', onTap: () => onAdjust(-60)),
                    const SizedBox(width: 6),
                    _AdjBtn(label: '- 30m', onTap: () => onAdjust(-30)),
                    const SizedBox(width: 14),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE8896A)),
                    ),
                    const SizedBox(width: 14),
                    _AdjBtn(label: '+ 30m', onTap: () => onAdjust(30)),
                    const SizedBox(width: 6),
                    _AdjBtn(label: '+ 1h', onTap: () => onAdjust(60)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdjBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AdjBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8896A).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE8896A)),
        ),
      ),
    );
  }
}
