import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/firestore_service.dart';

class SeniorHospitalAddScreen extends StatefulWidget {
  const SeniorHospitalAddScreen({super.key});

  @override
  State<SeniorHospitalAddScreen> createState() => _SeniorHospitalAddScreenState();
}

class _SeniorHospitalAddScreenState extends State<SeniorHospitalAddScreen> {
  final _hospitalController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _timeMinutes = 10 * 60;

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

  Future<void> _save(BuildContext context) async {
    final name = _hospitalController.text.trim();
    if (name.isEmpty) return;
    final date = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _timeMinutes ~/ 60, _timeMinutes % 60,
    );
    final appointment = Appointment(
      id: FirebaseFirestore.instance.collection('appointments').doc().id,
      hospitalName: name,
      date: date,
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
    );
    await FirestoreService.addAppointment(appointment);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
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
          '?ˆì•½ ì¶”ê?',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ë³‘ì› ?´ë¦„', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            TextField(
              controller: _hospitalController,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'ë³‘ì› ?´ë¦„ ?…ë ¥',
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
            const Text('? ì§œ', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
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
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFFE8896A), size: 28),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.year}??${_selectedDate.month}??${_selectedDate.day}??,
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
            const Text('?œê°„', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
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
                      color: Color(0xFFE8896A),
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
            const Text('ë©”ëª¨ (? íƒ)', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              style: const TextStyle(fontSize: 18),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'ë©”ëª¨ë¥??…ë ¥?˜ì„¸??,
                hintStyle: const TextStyle(fontSize: 18, color: Color(0xFFCCCCCC)),
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
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8896A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  '?€??,
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
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
          color: const Color(0xFFE8896A).withValues(alpha:0.1),
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
