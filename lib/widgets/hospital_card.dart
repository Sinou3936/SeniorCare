import 'package:flutter/material.dart';
import '../models/appointment.dart';

class HospitalCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;

  const HospitalCard({super.key, required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = appointment.date;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE8896A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_hospital,
                size: 36,
                color: Color(0xFFE8896A),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.hospitalName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${d.month}??${d.day}?? ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 17, color: Color(0xFF666666)),
                  ),
                  if (appointment.memo != null && appointment.memo!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      appointment.memo!,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF999999)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 28, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}
