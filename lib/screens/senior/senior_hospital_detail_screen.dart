import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import 'senior_hospital_edit_screen.dart';

class SeniorHospitalDetailScreen extends StatelessWidget {
  final Appointment appointment;

  const SeniorHospitalDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final d = appointment.date;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8896A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '병원 상세',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.local_hospital_rounded,
                    size: 48,
                    color: Color(0xFFE8896A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appointment.hospitalName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    text: '${d.year}년 ${d.month}월 ${d.day}일',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    text:
                        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
                  ),
                  if (appointment.memo != null && appointment.memo!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.notes_rounded, text: appointment.memo!),
                  ],
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SeniorHospitalEditScreen(appointment: appointment),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8896A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '수정',
                        style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () => _confirmDelete(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '삭제',
                        style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('예약 삭제', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: Text(
          '${appointment.hospitalName} 예약을 삭제할까요?',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(fontSize: 18, color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await NotificationService.cancelAppointmentAlarm(appointment.id);
      await FirestoreService.deleteAppointment(appointment.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: const Color(0xFFE8896A)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, color: Color(0xFF1A1A2E)),
          ),
        ),
      ],
    );
  }
}
