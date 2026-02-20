import '../api/contribution_api.dart';

class UserContribution {
  final String contributionId;
  final String campaignId;
  final String campaignTitle;
  final String campaignStatus;
  final double amount;
  final String status;
  final DateTime createdAt;

  UserContribution({
    required this.contributionId,
    required this.campaignId,
    required this.campaignTitle,
    required this.campaignStatus,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory UserContribution.fromJson(Map<String, dynamic> json) {
    return UserContribution(
      contributionId: json['contribution_id'],
      campaignId: json['campaign_id'],
      campaignTitle: json['campaign_title'],
      campaignStatus: json['campaign_status'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ContributionRepository {
  final ContributionApi _api = ContributionApi();

  Future<List<UserContribution>> getMyContributions() async {
    try {
      final List<dynamic> data = await _api.getMyContributions();
      return data.map((json) => UserContribution.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> contribute({
    required String campaignId,
    required double amount,
  }) async {
    try {
      return await _api.createContribution(
        campaignId: campaignId,
        amount: amount,
      );
    } catch (e) {
      rethrow;
    }
  }
}
