import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/pending_milestone.dart';

class PhaseReviewHeader extends StatelessWidget {
  final PendingMilestone milestone;

  const PhaseReviewHeader({super.key, required this.milestone});

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'KES ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Phase #${milestone.milestoneNumber}", 
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(milestone.description ?? "", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Possible payout", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  _formatCurrency(milestone.releaseAmount), 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "Campaign: ${milestone.campaignTitle}",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
