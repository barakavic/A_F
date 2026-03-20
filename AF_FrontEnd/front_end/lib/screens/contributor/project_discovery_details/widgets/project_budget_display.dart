import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/utils/currency_formatter.dart';

class ProjectBudgetDisplay extends StatelessWidget {
  final String? budgetData;

  const ProjectBudgetDisplay({super.key, this.budgetData});

  @override
  Widget build(BuildContext context) {
    if (budgetData == null || budgetData!.isEmpty) return const SizedBox.shrink();

    List<dynamic> items = [];
    try {
      items = jsonDecode(budgetData!);
    } catch (e) {
      return const SizedBox.shrink();
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Budget Breakdown",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              final String activity = item['activity'] ?? 'Unknown';
              final double amount = CurrencyFormatter.parse(item['amount']?.toString());

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity,
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                      ),
                    ),
                    Text(
                      "KES ${CurrencyFormatter.format(amount)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
