import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/firestore_service.dart';
import '../../widgets/hospital_card.dart';

class FamilyHospitalScreen extends StatefulWidget {
  const FamilyHospitalScreen({super.key});

  @override
  State<FamilyHospitalScreen> createState() => _FamilyHospitalScreenState();
}

class _FamilyHospitalScreenState extends State<FamilyHospitalScreen> {
  String? _seniorUid;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSeniorUid();
  }

  Future<void> _loadSeniorUid() async {
    final uid = await FirestoreService.getLinkedSeniorUid();
    if (mounted) setState(() { _seniorUid = uid; _loading = false; });
  }

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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A90D9)))
          : _seniorUid == null
              ? const Center(
                  child: Text('연결된 부모님이 없어요',
                      style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
                )
              : StreamBuilder<List<Appointment>>(
                  stream: FirestoreService.watchSeniorAppointments(_seniorUid!),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF4A90D9)));
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
                            Text('예약된 병원이 없어요',
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
                        onTap: () => _showDetail(context, appointments[i]),
                      ),
                    );
                  },
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
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 16),
            _Row(
                icon: Icons.calendar_today_rounded,
                text: '${d.year}년 ${d.month}월 ${d.day}일'),
            const SizedBox(height: 10),
            _Row(
              icon: Icons.access_time_rounded,
              text:
                  '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
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
