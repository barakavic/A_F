import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProjectFundingBar extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController amountController;
  final String? amountError;
  final bool isSubmitting;
  final VoidCallback onFundPressed;
  final Function(String) onAmountChanged;

  const ProjectFundingBar({
    super.key,
    required this.phoneController,
    required this.amountController,
    required this.amountError,
    required this.isSubmitting,
    required this.onFundPressed,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            hintText: "Phone (254...)",
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: TextField(
                          controller: amountController,
                          decoration: InputDecoration(
                            hintText: "Amount",
                            border: InputBorder.none,
                            prefixText: "KES ",
                            isDense: true,
                            errorText: amountError,
                            errorStyle: const TextStyle(fontSize: 10, height: 0.5),
                          ),
                          onChanged: onAmountChanged,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed:
                      (isSubmitting || amountError != null || amountController.text.isEmpty)
                          ? null
                          : onFundPressed,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("Fund Project",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
