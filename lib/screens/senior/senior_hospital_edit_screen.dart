import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/firestore_service.dart';

class SeniorHospitalEditScreen extends StatefulWidget {
  final Appointment appointment;
  const SeniorHospitalEditScreen({super.key, required this.appointment});

  @override
  State<SeniorHospitalEditScreen> createState() => _SeniorHospitalEditScreenState();
}

class _SeniorHospitalEditScreenState extends State<SeniorHospitalEditScreen> {
  late final TextEditingController _hospitalController;
  late final TextEditingController _memoController;
  late DateTime _selectedDate;
  late int _timeMinutes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final apt = widget.appointment;
    _hospitalController = TextEditingController(text: apt.hospitalName);
    _memoController = TextEditingController(text: apt.memo ?? '');
    _selectedDate = DateTime(apt.date.year, apt.date.month, apt.date.day);
    _timeMinutes = apt.date.hour * 60 + apt.date.minute;
  }

  @override
  void dispose() {
    _hospitalController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final h = (_timeMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (_timeMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _adjustTime(int delta) {
    setState(() => _timeMinutes = (_timeMinutes + delta).clamp(0, 23 * 60 + 59));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final name = _hospitalController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);

    final date = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _timeMinutes ~/ 60, _timeMinutes % 60,
    );
    final updated = Appointment(
      id: widget.appointment.id,
      hospitalName: name,
      date: date,
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
    );

    await FirestoreService.updateAppointment(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90D9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '예약 수정',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('병원 이름', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            TextField(
              controller: _hospitalController,
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
            const Text('날짜', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF4A90D9), size: 28),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('시간', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AdjBtn(label: '- 1h', onTap: () => _adjustTime(-60)),
                  const SizedBox(width: 6),
                  _AdjBtn(label: '- 30m', onTap: () => _adjustTime(-30)),
                  const SizedBox(width: 16),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90D9),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _AdjBtn(label: '+ 30m', onTap: () => _adjustTime(30)),
                  const SizedBox(width: 6),
                  _AdjBtn(label: '+ 1h', onTap: () => _adjustTime(60)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('메모 (선택)', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              style: const TextStyle(fontSize: 18),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '메모를 입력하세요',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90D9),
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
          color: const Color(0xFF4A90D9).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A90D9),
          ),
        ),
      ),
    );
  }
}
