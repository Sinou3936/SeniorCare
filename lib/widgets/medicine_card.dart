import 'package:flutter/material.dart';
import '../models/medicine.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;

  const MedicineCard({super.key, required this.medicine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE8896A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: medicine.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(medicine.photoUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.medication, size: 44, color: Color(0xFFE8896A)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: medicine.times.map((t) => _TimeChip(label: t)).toList(),
                  ),
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

class _TimeChip extends StatelessWidget {
  final String label;
  const _TimeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8896A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFFE8896A),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
