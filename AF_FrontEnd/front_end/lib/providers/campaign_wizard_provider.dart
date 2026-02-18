import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project.dart';

class CampaignWizardState {
  final String title;
  final String description;
  final double goalAmount;
  final int durationMonths;
  final String category;
  final double? riskFactor;
  final int? phaseCount;
  final List<dynamic>? milestones;
  final int currentStep;
  final bool isLoading;

  CampaignWizardState({
    this.title = '',
    this.description = '',
    this.goalAmount = 0.0,
    this.durationMonths = 1,
    this.category = 'Water & Sanitation',
    this.riskFactor,
    this.phaseCount,
    this.milestones,
    this.currentStep = 0,
    this.isLoading = false,
  });

  CampaignWizardState copyWith({
    String? title,
    String? description,
    double? goalAmount,
    int? durationMonths,
    String? category,
    double? riskFactor,
    int? phaseCount,
    List<dynamic>? milestones,
    int? currentStep,
    bool? isLoading,
  }) {
    return CampaignWizardState(
      title: title ?? this.title,
      description: description ?? this.description,
      goalAmount: goalAmount ?? this.goalAmount,
      durationMonths: durationMonths ?? this.durationMonths,
      category: category ?? this.category,
      riskFactor: riskFactor ?? this.riskFactor,
      phaseCount: phaseCount ?? this.phaseCount,
      milestones: milestones ?? this.milestones,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Project toProject(String fundraiserId) {
    return Project(
      title: title,
      description: description,
      goalAmount: goalAmount,
      durationMonths: durationMonths,
      fundraiserId: fundraiserId,
    );
  }
}

class CampaignWizardNotifier extends Notifier<CampaignWizardState> {
  @override
  CampaignWizardState build() {
    return CampaignWizardState();
  }

  void updateBasicInfo(String title, String description) {
    state = state.copyWith(title: title, description: description);
  }

  void updateFinancials(double goal, int duration) {
    state = state.copyWith(goalAmount: goal, durationMonths: duration);
  }

  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

final campaignWizardProvider = NotifierProvider<CampaignWizardNotifier, CampaignWizardState>(() {
  return CampaignWizardNotifier();
});
