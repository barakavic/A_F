import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProjectFundingProgress extends StatelessWidget {
  final double raised;
  final double goal;

  const ProjectFundingProgress({
    super.key,
    required this.raised,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = goal > 0 ? raised / goal : 0.0;
    final int percentage = (progress * 100).toInt().clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Progress", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("$percentage%",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 12,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "KES ${raised.toInt()} raised of KES ${goal.toInt()} goal",
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }
}
