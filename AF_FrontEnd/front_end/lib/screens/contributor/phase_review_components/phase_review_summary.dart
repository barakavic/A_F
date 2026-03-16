import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/pending_milestone.dart';

class PhaseReviewSummary extends StatelessWidget {
  final PendingMilestone milestone;

  const PhaseReviewSummary({super.key, required this.milestone});

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'KES ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PhaseSummaryItem(
                label: "Ttl Payout Expected", 
                value: _formatCurrency(milestone.releaseAmount)
              ),
              _PhaseSummaryItem(
                label: "Proof Status", 
                value: milestone.evidenceDescription != null ? "Provided" : "Pending Detail"
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Phase Status: ", style: TextStyle(color: Colors.grey, fontSize: 12)),
              _buildStatusPill("Ready for Vote", Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _PhaseSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _PhaseSummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
