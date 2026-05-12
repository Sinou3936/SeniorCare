import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medicine.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../utils/time_utils.dart';

class SeniorMedicineAddScreen extends StatefulWidget {
  const SeniorMedicineAddScreen({super.key});

  @override
  State<SeniorMedicineAddScreen> createState() => _SeniorMedicineAddScreenState();
}

class _SeniorMedicineAddScreenState extends State<SeniorMedicineAddScreen> {
  final _nameController = TextEditingController();

  DateTime? _endDate;

  final Map<String, int> _times = {
    '?ÑÏπ®': 8 * 60,
    '?êÏã¨': 12 * 60,
    '?Ä??: 18 * 60,
    'Ï∑®Ïπ®': 21 * 60,
  };
  final Map<String, bool> _timeEnabled = {
    '?ÑÏπ®': true,
    '?êÏã¨': true,
    '?Ä??: true,
    'Ï∑®Ïπ®': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _adjustTime(String slot, int delta) {
    setState(() {
      _times[slot] = (_times[slot]! + delta).clamp(0, 23 * 60 + 59);
    });
  }

  Future<void> _save(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final enabledSlots = _timeEnabled.entries
        .where((e) => e.value)
        .map((e) {
          final h = _times[e.key]! ~/ 60;
          final m = _times[e.key]! % 60;
          return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        })
        .toList();

    final medicine = Medicine(
      id: FirebaseFirestore.instance.collection('medicines').doc().id,
      name: name,
      times: enabledSlots,
      startDate: kstNow(),
      endDate: _endDate,
    );
    await FirestoreService.addMedicine(medicine);
    await Future.wait([
      NotificationService.scheduleMedicineAlarms(
        medicineId: medicine.id,
        medicineName: medicine.name,
        times: enabledSlots,
      ),
      FirestoreService.generateLogsForDate(kstNow()),
    ]);

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8896A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '??Ï∂îÍ?',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('???¥Î¶Ñ',
                style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '???¥Î¶Ñ ?ÖÎ†•',
                hintStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCCCCCC)),
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
            const Text(
              'Î≥µÏö© ?úÍ∞Ñ ?§Ï†ï',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            ..._times.keys.map((slot) => _TimeRow(
                  slot: slot,
                  enabled: _timeEnabled[slot]!,
                  formattedTime: _formatTime(_times[slot]!),
                  onToggle: (v) => setState(() => _timeEnabled[slot] = v),
                  onAdjust: (delta) => _adjustTime(slot, delta),
                )),
            const SizedBox(height: 24),
            const Text(
              'Î≥µÏö© Ï¢ÖÎ£å??,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
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
                            ? '${_endDate!.year}??${_endDate!.month}??${_endDate!.day}?ºÍπåÏßÄ'
                            : 'Ï¢ÖÎ£å???ÜÏùå (Í≥ÑÏÜç Î≥µÏö©)',
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
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8896A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  '?Ä??,
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
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
          color: enabled
              ? const Color(0xFFE8896A)
              : const Color(0xFFE0E0E0),
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
                  color: enabled
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFFCCCCCC),
                ),
              ),
            ],
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE8896A),
                    ),
                  ),
                  const SizedBox(width: 14),
                  _AdjBtn(label: '+ 30m', onTap: () => onAdjust(30)),
                  const SizedBox(width: 6),
                  _AdjBtn(label: '+ 1h', onTap: () => onAdjust(60)),
                ],
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE8896A),
          ),
        ),
      ),
    );
  }
}
