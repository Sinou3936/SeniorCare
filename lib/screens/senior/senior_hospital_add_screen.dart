import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/connectivity_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../utils/recent_hospitals.dart';
import '../../utils/tap_guard.dart';

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
  bool _isSaving = false;
  final _saveGuard = TapGuard();
  List<RecentHospital> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  // 실패해도(오프라인 등) 버튼만 안 보일 뿐 직접 입력은 그대로 가능
  Future<void> _loadRecent() async {
    try {
      final all = await FirestoreService.getRecentAppointments();
      if (mounted) setState(() => _recent = recentHospitals(all));
    } catch (_) {}
  }

  void _pickRecent(RecentHospital h) {
    setState(() {
      _hospitalController.text = h.name;
      _timeMinutes = h.timeMinutes;
    });
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

  Future<void> _save(BuildContext context) async {
    final name = _hospitalController.text.trim();
    if (name.isEmpty || _isSaving) return;
    if (!await ensureOnline(context,
        message: '오프라인에서는 병원 예약을 추가·수정·삭제할 수 없어요.\nWi-Fi나 데이터를 켜고 다시 시도해주세요.')) {
      return;
    }
    if (!context.mounted) return;
    setState(() => _isSaving = true);
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
    await NotificationService.scheduleAppointmentAlarm(appointment);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ko', 'KR'),
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
          '예약 추가',
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
                hintText: '병원 이름 입력',
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
            if (_recent.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('최근 병원',
                  style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final h in _recent)
                    GestureDetector(
                      onTap: () => _pickRecent(h),
                      child: Container(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFE8896A), width: 2),
                        ),
                        child: Text(
                          h.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE8896A),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
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
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFFE8896A), size: 28),
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
              child: FittedBox(
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
                onPressed:
                    _isSaving ? null : () => _saveGuard.run(() => _save(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8896A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '저장',
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
