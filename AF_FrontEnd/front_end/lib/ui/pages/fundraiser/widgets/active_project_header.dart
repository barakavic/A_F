import 'package:flutter/material.dart';
import '../../../../data/models/project.dart';
import '../../../../core/constants/app_colors.dart';

class ActiveProjectHeader extends StatelessWidget {
  final Project project;

  const ActiveProjectHeader({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.title, 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "This roadmap is generated based on our governance algorithm to ensure transparency and accountability.",
            style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statItem("TOTAL BUDGET", "KES ${project.goalAmount.toInt()}"),
        _statItem("PHASES", project.numPhases.toString()),
        _statItem("STATUS", project.status.toUpperCase(), color: _getProjectStatusColor(project.status)),
      ],
    );
  }

  Color _getProjectStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return Colors.grey;
      case 'active': return Colors.blue;
      case 'funded': return Colors.green;
      case 'in_phases': return Colors.orange;
      case 'completed': return Colors.purple;
      default: return AppColors.primary;
    }
  }

  Widget _statItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
