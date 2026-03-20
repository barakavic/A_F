import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_end/core/constants/app_colors.dart';
import 'package:front_end/providers/campaign_wizard_provider.dart';
import 'package:front_end/core/utils/currency_formatter.dart';
import 'wizard_shared_widgets.dart';
import 'budget_builder.dart';

class Step3Category extends ConsumerWidget {
  final GlobalKey<FormState> formKey;

  const Step3Category({
    super.key,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campaignWizardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Proposed Budget",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Break down how you plan to use the KES ${CurrencyFormatter.format(state.goalAmount)} funding.",
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            WizardDropdown(
              label: "Industry Category",
              value: state.category,
              items: const ["Water & Sanitation", "Green Energy", "Education", "Healthcare", "Technology", "Agriculture"],
              onChanged: (v) {
                ref.read(campaignWizardProvider.notifier).updateCategory(v!);
              },
            ),
            const SizedBox(height: 48),
            const Text(
              "Algorithmic Preview",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildAlgoPreview(state),
            const SizedBox(height: 48),
            const BudgetBuilder(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgoPreview(CampaignWizardState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAlgoStat("Risk factor (C)", state.estimatedRiskC.toStringAsFixed(3), Colors.orange),
              Container(height: 30, width: 1, color: Colors.grey.shade200),
              _buildAlgoStat("Phase count (P)", state.estimatedPhaseCount.toString(), Colors.blue),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAlgoStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
