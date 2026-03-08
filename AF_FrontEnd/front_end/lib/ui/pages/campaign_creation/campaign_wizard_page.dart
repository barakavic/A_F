import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import '../../../providers/campaign_wizard_provider.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/auth_provider.dart' as auth;
import 'widgets/wizard_shared_widgets.dart';
import 'widgets/step_1_basic_info.dart';
import 'widgets/step_2_financials.dart';
import 'widgets/step_3_category.dart';
import 'widgets/step_4_review.dart';
import 'widgets/wizard_footer.dart';

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
    
    // Fetch the actual fundraiser ID from AuthProvider
    final fundraiserId = legacy_provider.Provider.of<auth.AuthProvider>(context, listen: false).userId;
    
    if (fundraiserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.'), backgroundColor: Colors.red),
      );
      return;
    }

    final project = state.toProject(fundraiserId);

    ref.read(campaignWizardProvider.notifier).setLoading(true);

    try {
      final campaignId = await ref.read(projectServiceProvider).createProject(project);
      
      if (campaignId != null && mounted) {
        // Upload image if provided
        if (state.coverImagePath != null) {
          await ref.read(projectServiceProvider).uploadCoverImage(campaignId, state.coverImagePath!);
        }

        await ref.read(projectServiceProvider).launchProject(campaignId);
        
        ref.invalidate(activeProjectsProvider);
        ref.invalidate(myProjectsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign created successfully!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create campaign: Unknown error'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $message'), backgroundColor: Colors.red),
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
          WizardProgressBar(currentStep: state.currentStep),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1BasicInfo(
                  formKey: _formKeys[0],
                  titleController: _titleController,
                  descController: _descController,
                ),
                Step2Financials(
                  formKey: _formKeys[1],
                  goalController: _goalController,
                  durationController: _durationController,
                ),
                Step3Category(formKey: _formKeys[2]),
                Step4Review(formKey: _formKeys[3]),
              ],
            ),
          ),
          WizardFooter(
            currentStep: state.currentStep,
            isLoading: state.isLoading,
            onBack: _previousStep,
            onNext: _nextStep,
          ),
        ],
      ),
    );
  }
}
