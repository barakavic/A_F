class Project {
  final String? id;
  final String title;
  final String description;
  final double goalAmount;
  final double raisedAmount;
  final String status;
  final int durationMonths;
  final double? alphaValue;
  final double phaseProgress; 
  final String? fundraiserId;

  Project({
    this.id,
    required this.title,
    required this.description,
    required this.goalAmount,
    this.raisedAmount = 0.0,
    required this.durationMonths,
    this.status = 'draft',
    this.alphaValue,
    this.phaseProgress = 0.0,
    this.fundraiserId,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['campaign_id']?.toString(),
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? '',
      goalAmount: (json['funding_goal_f'] as num?)?.toDouble() ?? 0.0,
      raisedAmount: (json['total_contributions'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'draft',
      durationMonths: json['duration_d'] ?? 12,
      phaseProgress: 0.0, 
      fundraiserId: json['fundraiser_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'funding_goal_f': goalAmount,
      'duration_d': durationMonths,
      'fundraiser_id': fundraiserId,
      'campaign_type_ct': 'donation', 
      'category_c': 0.5, 
      'alpha_value': 0.5, 
    };
  }
}
