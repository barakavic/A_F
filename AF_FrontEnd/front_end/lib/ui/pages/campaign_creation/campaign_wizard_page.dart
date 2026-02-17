import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/campaign_wizard_provider.dart';
import '../../../providers/project_provider.dart';

class CampaignWizardPage extends ConsumerStatefulWidget {
  const CampaignWizardPage({super.key});

  @override
  ConsumerState<CampaignWizardPage> createState() => _CampaignWizardPageState();
}

class _CampaignWizardPageState extends ConsumerState<CampaignWizardPage> {
  final PageController _pageController = PageController();
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  // Controllers for Step 1
  late TextEditingController _titleController;
  late TextEditingController _descController;

  // Controllers for Step 2
  late TextEditingController _goalController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(campaignWizardProvider);
    _titleController = TextEditingController(text: state.title);
    _descController = TextEditingController(text: state.description);
    _goalController = TextEditingController(text: state.goalAmount > 0 ? state.goalAmount.toString() : '');
    _durationController = TextEditingController(text: state.durationMonths > 1 ? state.durationMonths.toString() : '');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _goalController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final step = ref.read(campaignWizardProvider).currentStep;
    if (_formKeys[step].currentState!.validate()) {
      // Save current step data
      if (step == 0) {
        ref.read(campaignWizardProvider.notifier).updateBasicInfo(
              _titleController.text,
              _descController.text,
            );
      } else if (step == 1) {
        ref.read(campaignWizardProvider.notifier).updateFinancials(
              double.tryParse(_goalController.text) ?? 0.0,
              int.tryParse(_durationController.text) ?? 1,
            );
      }

      if (step < 3) {
        ref.read(campaignWizardProvider.notifier).nextStep();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submit();
      }
    }
  }

  void _previousStep() {
    final step = ref.read(campaignWizardProvider).currentStep;
    if (step > 0) {
      ref.read(campaignWizardProvider.notifier).previousStep();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submit() async {
    final state = ref.read(campaignWizardProvider);
    
    // Using the dev account UUID directly to avoid session retrieval hassle for the panel demo
    const fundraiserId = "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"; 

    final project = state.toProject(fundraiserId);

    ref.read(campaignWizardProvider.notifier).setLoading(true);

    try {
      final success = await ref.read(projectServiceProvider).createProject(project);
      if (success && mounted) {
        ref.invalidate(activeProjectsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign created successfully!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create campaign'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) ref.read(campaignWizardProvider.notifier).setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campaignWizardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              "New Campaign",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "Step ${state.currentStep + 1} of 4",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressBar(state.currentStep),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
              ],
            ),
          ),
          _buildFooter(state.currentStep),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
              decoration: BoxDecoration(
                color: index <= currentStep ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's your project about?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Provide a clear and compelling title and description for your campaign.",
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              label: "Campaign Title",
              controller: _titleController,
              hint: "e.g., Clean Water for Kitui",
              validator: (v) => v!.length < 5 ? "Title is too short" : null,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: "Story & Description",
              controller: _descController,
              hint: "Explain why this project matters...",
              maxLines: 6,
              validator: (v) => v!.length < 20 ? "Description is too short" : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[1],
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
            _buildTextField(
              label: "Funding Goal (KES)",
              controller: _goalController,
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
            _buildTextField(
              label: "Estimated Duration (Months)",
              controller: _durationController,
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

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[2],
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
            _buildDropdown(
              label: "Industry Category",
              value: ref.watch(campaignWizardProvider).category,
              items: ["Water & Sanitation", "Green Energy", "Education", "Healthcare", "Technology", "Agriculture"],
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
            _buildAlgoPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4() {
    final state = ref.watch(campaignWizardProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Review Your Campaign",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Check everything one last time before submitting.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            _buildSummaryTile("Title", state.title),
            _buildSummaryTile("Goal", "KES ${state.goalAmount}"),
            _buildSummaryTile("Duration", "${state.durationMonths} Months"),
            _buildSummaryTile("Industry", state.category),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Description Preview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(state.description, style: const TextStyle(fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgoPreview() {
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
              _buildAlgoStat("Risk factor (C)", "0.125", Colors.orange),
              Container(height: 30, width: 1, color: Colors.grey.shade200),
              _buildAlgoStat("Phase count (P)", "6", Colors.blue),
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
          _buildMiniWeightChart(),
        ],
      ),
    );
  }

  Widget _buildMiniWeightChart() {
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(6, (index) {
          final height = 20.0 + (index * 8);
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: height,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2 + (index * 0.1)),
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

  Widget _buildSummaryTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFooter(int currentStep) {
    final isLoading = ref.watch(campaignWizardProvider).isLoading;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Back"),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(currentStep == 3 ? "Complete & Submit" : "Continue"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    bool isNumber = false,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
