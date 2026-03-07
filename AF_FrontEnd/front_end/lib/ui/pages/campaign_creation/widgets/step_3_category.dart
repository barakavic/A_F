import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_end/core/constants/app_colors.dart';
import 'package:front_end/providers/campaign_wizard_provider.dart';
import 'wizard_shared_widgets.dart';

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
              "Category & Analysis",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Select your industry to help us analyze the risk.",
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
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Milestone Weighting", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Icon(Icons.auto_graph, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          _buildMiniWeightChart(state.estimatedPhaseCount),
        ],
      ),
    );
  }

  Widget _buildMiniWeightChart(int count) {
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(count, (index) {
          final height = 20.0 + (index * 8);
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: height,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity((0.2 + (index * 0.1)).clamp(0.1, 1.0)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
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
