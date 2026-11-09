import 'package:flutter/material.dart';

import '../models/reimbursement.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ReimbursementStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      ReimbursementStatus.pending => ('Pendiente', const Color(0xFFB7791F), Icons.schedule),
      ReimbursementStatus.approved => ('Aprobada', const Color(0xFF2F855A), Icons.check_circle),
      ReimbursementStatus.rejected => ('Rechazada', const Color(0xFFC53030), Icons.cancel),
      ReimbursementStatus.unknown => ('Desconocido', Colors.grey, Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
