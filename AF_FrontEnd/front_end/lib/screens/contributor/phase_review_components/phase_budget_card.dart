import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/pending_milestone.dart';

class PhaseBudgetCard extends StatelessWidget {
  final PendingMilestone milestone;

  const PhaseBudgetCard({super.key, required this.milestone});

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'KES ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Milestone Budget Breakdown"),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              _buildBudgetItem(milestone.description ?? "", _formatCurrency(milestone.releaseAmount)),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Release", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_formatCurrency(milestone.releaseAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildBudgetItem(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
