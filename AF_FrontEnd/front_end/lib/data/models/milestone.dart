class Milestone {
  final String id;
  final int milestoneNumber;
  final String? description;
  final double phaseWeight;
  final double disbursementPercentage;
  final double releaseAmount;
  final String status;
  final DateTime? activatedAt;
  final DateTime? evidenceSubmittedAt;
  final DateTime? votingStartDate;
  final DateTime? votingEndDate;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? fundsReleasedAt;
  final DateTime? targetDeadline;
  final int revisionCount;
  final int maxRevisions;

  Milestone({
    required this.id,
    required this.milestoneNumber,
    this.description,
    required this.phaseWeight,
    required this.disbursementPercentage,
    required this.releaseAmount,
    required this.status,
    this.activatedAt,
    this.evidenceSubmittedAt,
    this.votingStartDate,
    this.votingEndDate,
    this.approvedAt,
    this.rejectedAt,
    this.fundsReleasedAt,
    this.targetDeadline,
    this.revisionCount = 0,
    this.maxRevisions = 1,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      return DateTime.tryParse(dateStr);
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return Milestone(
      id: json['milestone_id']?.toString() ?? '',
      milestoneNumber: parseInt(json['milestone_number']),
      description: json['description'],
      phaseWeight: parseDouble(json['phase_weight_wi']),
      disbursementPercentage: parseDouble(json['disbursement_percentage_di']),
      releaseAmount: parseDouble(json['release_amount']),
      status: json['status'] ?? 'pending',
      activatedAt: parseDate(json['activated_at']),
      evidenceSubmittedAt: parseDate(json['evidence_submitted_at']),
      votingStartDate: parseDate(json['voting_start_date']),
      votingEndDate: parseDate(json['voting_end_date']),
      approvedAt: parseDate(json['approved_at']),
      rejectedAt: parseDate(json['rejected_at']),
      fundsReleasedAt: parseDate(json['funds_released_at']),
      targetDeadline: parseDate(json['target_deadline']),
      revisionCount: parseInt(json['revision_count']),
      maxRevisions: parseInt(json['max_revisions'], defaultValue: 1),
    );
  }
}
