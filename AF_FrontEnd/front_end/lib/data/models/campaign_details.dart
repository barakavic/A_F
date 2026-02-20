import 'milestone.dart';

class CampaignDetails {
  final String campaignId;
  final String fundraiserId;
  final String title;
  final String description;
  final double fundingGoal;
  final int durationMonths;
  final String status;
  final double categoryRisk;
  final int numPhases;
  final double alphaValue;
  final double totalContributions;
  final double totalReleased;
  final DateTime createdAt;
  final List<Milestone> milestones;
  final int currentMilestoneNumber;
  final int milestonesApprovedCount;

  CampaignDetails({
    required this.campaignId,
    required this.fundraiserId,
    required this.title,
    required this.description,
    required this.fundingGoal,
    required this.durationMonths,
    required this.status,
    required this.categoryRisk,
    required this.numPhases,
    required this.alphaValue,
    required this.totalContributions,
    required this.totalReleased,
    required this.createdAt,
    required this.milestones,
    required this.currentMilestoneNumber,
    required this.milestonesApprovedCount,
  });

  factory CampaignDetails.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return CampaignDetails(
      campaignId: json['campaign_id'],
      fundraiserId: json['fundraiser_id'],
      title: json['title'],
      description: json['description'],
      fundingGoal: parseDouble(json['funding_goal_f']),
      durationMonths: json['duration_d'],
      status: json['status'],
      categoryRisk: parseDouble(json['category_c']),
      numPhases: json['num_phases_p'],
      alphaValue: parseDouble(json['alpha_value']),
      totalContributions: parseDouble(json['total_contributions']),
      totalReleased: parseDouble(json['total_released']),
      createdAt: DateTime.parse(json['created_at']),
      milestones: (json['milestones'] as List? ?? [])
          .map((m) => Milestone.fromJson(m))
          .toList(),
      currentMilestoneNumber: json['current_milestone_number'] ?? 0,
      milestonesApprovedCount: json['milestones_approved_count'] ?? 0,
    );
  }
}
