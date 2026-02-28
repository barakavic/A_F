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
      amount: _parseDouble(json['amount']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
