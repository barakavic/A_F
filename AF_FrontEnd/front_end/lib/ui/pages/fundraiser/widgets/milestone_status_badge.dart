import 'package:flutter/material.dart';

class MilestoneStatusBadge extends StatelessWidget {
  final String status;

  const MilestoneStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'active') color = Colors.blue;
    if (status == 'released' || status == 'approved') color = Colors.green;
    if (status == 'evidence_submitted' || status == 'voting_open') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
