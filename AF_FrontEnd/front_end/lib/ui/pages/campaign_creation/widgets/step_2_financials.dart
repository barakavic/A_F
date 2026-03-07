import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wizard_shared_widgets.dart';

class Step2Financials extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController goalController;
  final TextEditingController durationController;

  const Step2Financials({
    super.key,
    required this.formKey,
    required this.goalController,
    required this.durationController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Financial Goals",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Define how much you need and how long it will take to complete the project.",
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            WizardTextField(
              label: "Funding Goal (KES)",
              controller: goalController,
              hint: "1,000,000",
              isNumber: true,
              prefixIcon: Icons.payments_outlined,
              validator: (v) {
                final val = double.tryParse(v ?? '');
                if (val == null || val < 1000) return "Minimum goal is KES 1,000";
                return null;
              },
            ),
            const SizedBox(height: 24),
            WizardTextField(
              label: "Estimated Duration (Months)",
              controller: durationController,
              hint: "e.g., 6",
              isNumber: true,
              prefixIcon: Icons.timer_outlined,
              validator: (v) {
                final val = int.tryParse(v ?? '');
                if (val == null || val < 1) return "Minimum duration is 1 month";
                if (val > 24) return "Maximum duration is 24 months";
                return null;
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Our algorithm will use these details to calculate your risk factor and milestone breakdown.",
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
