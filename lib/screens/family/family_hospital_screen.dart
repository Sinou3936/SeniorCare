import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../widgets/hospital_card.dart';

class FamilyHospitalScreen extends StatelessWidget {
  const FamilyHospitalScreen({super.key});

  static final _appointments = [
    Appointment(
      id: 'a1',
      hospitalName: '서울내과의원',
      date: DateTime.now().add(const Duration(days: 3, hours: 2)),
      memo: '혈압약 처방 갱신',
    ),
    Appointment(
      id: 'a2',
      hospitalName: '한양대학병원',
      date: DateTime.now().add(const Duration(days: 7)),
      memo: '정기 검진',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90D9),
        title: const Text(
          '부모님 병원 예약',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _appointments.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital_outlined, size: 72, color: Color(0xFFCCCCCC)),
                  SizedBox(height: 16),
                  Text(
                    '예약된 병원이 없어요',
                    style: TextStyle(fontSize: 20, color: Color(0xFF999999)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _appointments.length,
              itemBuilder: (context, i) => HospitalCard(
                appointment: _appointments[i],
                onTap: () => _showDetail(context, _appointments[i]),
              ),
            ),
    );
  }

  void _showDetail(BuildContext context, Appointment apt) {
    final d = apt.date;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              apt.hospitalName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 16),
            _Row(icon: Icons.calendar_today_rounded, text: '${d.year}년 ${d.month}월 ${d.day}일'),
            const SizedBox(height: 10),
            _Row(
              icon: Icons.access_time_rounded,
              text: '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
            ),
            if (apt.memo != null && apt.memo!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _Row(icon: Icons.notes_rounded, text: apt.memo!),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF4A90D9)),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 20, color: Color(0xFF1A1A2E))),
      ],
    );
  }
}
