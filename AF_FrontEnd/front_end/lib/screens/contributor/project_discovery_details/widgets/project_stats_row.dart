import 'package:flutter/material.dart';

class ProjectStatsRow extends StatelessWidget {
  final int daysLeft;
  final int backersCount;

  const ProjectStatsRow({
    super.key,
    required this.daysLeft,
    required this.backersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatBadge(Icons.timer_outlined, "$daysLeft Days Left", Colors.blue),
        _buildStatBadge(Icons.people_outline, "$backersCount Backers", Colors.green),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
