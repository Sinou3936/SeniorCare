import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/firestore_service.dart';
import '../../widgets/hospital_card.dart';
import 'senior_hospital_detail_screen.dart';
import 'senior_hospital_add_screen.dart';

class SeniorHospitalScreen extends StatelessWidget {
  const SeniorHospitalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8896A),
        title: const Text(
          'Î≥ëÏõê ?àÏïΩ',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: FirestoreService.watchAppointments(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE8896A)));
          }
          final appointments = snap.data ?? [];
          if (appointments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital_outlined,
                      size: 72, color: Color(0xFFCCCCCC)),
                  SizedBox(height: 16),
                  Text('?àÏïΩ??Î≥ëÏõê???ÜÏñ¥??,
                      style: TextStyle(fontSize: 20, color: Color(0xFF999999))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: appointments.length,
            itemBuilder: (context, i) => HospitalCard(
              appointment: appointments[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SeniorHospitalDetailScreen(appointment: appointments[i]),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SeniorHospitalAddScreen()),
        ),
        backgroundColor: const Color(0xFFE8896A),
        icon: const Icon(Icons.add, size: 28, color: Colors.white),
        label: const Text(
          '?àÏïΩ Ï∂îÍ?',
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
