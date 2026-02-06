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
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Project(
      id: json['campaign_id']?.toString(),
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? '',
      goalAmount: parseDouble(json['funding_goal_f']),
      raisedAmount: parseDouble(json['total_contributions']),
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
      'funding_goal': goalAmount,
      'duration_months': durationMonths,
      'campaign_type': 'donation', 
    };
  }
}
