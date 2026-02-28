class PendingMilestone {
  final String milestoneId;
  final int milestoneNumber;
  final String description;
  final String campaignTitle;
  final String campaignId;
  final DateTime votingEndDate;
  final double releaseAmount;
  final String? evidenceDescription;

  PendingMilestone({
    required this.milestoneId,
    required this.milestoneNumber,
    required this.description,
    required this.campaignTitle,
    required this.campaignId,
    required this.votingEndDate,
    required this.releaseAmount,
    this.evidenceDescription,
  });

  factory PendingMilestone.fromJson(Map<String, dynamic> json) {
    return PendingMilestone(
      milestoneId: json['milestone_id'],
      milestoneNumber: json['milestone_number'],
      description: json['description'],
      campaignTitle: json['campaign_title'],
      campaignId: json['campaign_id'],
      votingEndDate: DateTime.parse(json['voting_end_date']),
      releaseAmount: (json['release_amount'] as num).toDouble(),
      evidenceDescription: json['evidence_description'],
    );
  }

  int get daysLeft {
    return votingEndDate.difference(DateTime.now()).inDays;
  }
}
