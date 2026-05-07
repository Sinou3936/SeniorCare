import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../widgets/hospital_card.dart';
import 'senior_hospital_detail_screen.dart';
import 'senior_hospital_add_screen.dart';

class SeniorHospitalScreen extends StatelessWidget {
  const SeniorHospitalScreen({super.key});

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
          '병원 예약',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                  Text('예약된 병원이 없어요', style: TextStyle(fontSize: 20, color: Color(0xFF999999))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _appointments.length,
              itemBuilder: (context, i) => HospitalCard(
                appointment: _appointments[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SeniorHospitalDetailScreen(appointment: _appointments[i]),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SeniorHospitalAddScreen()),
        ),
        backgroundColor: const Color(0xFF4A90D9),
        icon: const Icon(Icons.add, size: 28, color: Colors.white),
        label: const Text(
          '예약 추가',
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
