import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../services/connectivity_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/medicine_card.dart';
import 'senior_medicine_detail_screen.dart';
import 'senior_medicine_add_screen.dart';

class SeniorMedicineScreen extends StatelessWidget {
  const SeniorMedicineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8896A),
        title: const Text(
          '내 약',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Medicine>>(
        stream: FirestoreService.watchMedicines(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE8896A)));
          }
          final medicines = snap.data ?? [];
          if (medicines.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined, size: 72, color: Color(0xFFCCCCCC)),
                  SizedBox(height: 16),
                  Text('등록된 약이 없어요',
                      style: TextStyle(fontSize: 20, color: Color(0xFF999999))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: medicines.length,
            itemBuilder: (context, i) => MedicineCard(
              medicine: medicines[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SeniorMedicineDetailScreen(medicine: medicines[i]),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 추가는 진입 전에 온라인 확인 (폼 다 채우고 저장 때 막히는 것 방지)
          if (!await ensureOnline(context,
              message: '오프라인에서는 약을 추가할 수 없어요.\nWi-Fi나 데이터를 켜고 다시 시도해주세요.')) {
            return;
          }
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SeniorMedicineAddScreen()),
          );
        },
        backgroundColor: const Color(0xFFE8896A),
        icon: const Icon(Icons.add, size: 28, color: Colors.white),
        label: const Text(
          '약 추가',
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
