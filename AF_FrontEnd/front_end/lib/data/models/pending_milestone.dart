class PendingMilestone {
  final String milestoneId;
  final int milestoneNumber;
  final String description;
  final String campaignTitle;
  final String campaignId;
  final DateTime votingEndDate;
  final double releaseAmount;
  final String? evidenceDescription;
  final List<String> evidenceImageUrls;

  PendingMilestone({
    required this.milestoneId,
    required this.milestoneNumber,
    required this.description,
    required this.campaignTitle,
    required this.campaignId,
    required this.votingEndDate,
    required this.releaseAmount,
    this.evidenceDescription,
    this.evidenceImageUrls = const [],
  });

  factory PendingMilestone.fromJson(Map<String, dynamic> json) {
    return PendingMilestone(
      milestoneId: json['milestone_id'],
      milestoneNumber: _parseInt(json['milestone_number']),
      description: json['description'],
      campaignTitle: json['campaign_title'],
      campaignId: json['campaign_id'],
      votingEndDate: DateTime.parse(json['voting_end_date']),
      releaseAmount: _parseDouble(json['release_amount']),
      evidenceDescription: json['evidence_description'],
      evidenceImageUrls: _parseListString(json['evidence_image_urls']),
    );
  }

  static List<String> _parseListString(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((v) => v.toString()).toList();
    return [];
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  int get daysLeft {
    return votingEndDate.difference(DateTime.now()).inDays;
  }
}
