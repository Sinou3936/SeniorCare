import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../widgets/medicine_card.dart';
import 'senior_medicine_detail_screen.dart';
import 'senior_medicine_add_screen.dart';

class SeniorMedicineScreen extends StatelessWidget {
  const SeniorMedicineScreen({super.key});

  static final _medicines = [
    Medicine(
      id: 'm1',
      name: '혈압약',
      times: ['아침', '저녁'],
      startDate: DateTime(2025, 1, 1),
    ),
    Medicine(
      id: 'm2',
      name: '당뇨약',
      times: ['점심'],
      startDate: DateTime(2025, 3, 1),
    ),
    Medicine(
      id: 'm3',
      name: '비타민',
      times: ['취침'],
      startDate: DateTime(2025, 1, 15),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90D9),
        title: const Text(
          '내 약',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _medicines.isEmpty
          ? const _EmptyState(message: '등록된 약이 없어요')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _medicines.length,
              itemBuilder: (context, i) => MedicineCard(
                medicine: _medicines[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SeniorMedicineDetailScreen(medicine: _medicines[i]),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SeniorMedicineAddScreen()),
        ),
        backgroundColor: const Color(0xFF4A90D9),
        icon: const Icon(Icons.add, size: 28, color: Colors.white),
        label: const Text(
          '약 추가',
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.medication_outlined, size: 72, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 20, color: Color(0xFF999999))),
        ],
      ),
    );
  }
}
