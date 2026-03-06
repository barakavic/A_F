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
  final String? fundraiserName;
  final int backersCount;
  final int daysLeft;
  final String category;
  final int numPhases;
  final String? coverImageUrl;

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
    this.fundraiserName,
    this.backersCount = 0,
    this.daysLeft = 0,
    this.category = 'General',
    this.numPhases = 0,
    this.coverImageUrl,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
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

    return Project(
      id: json['campaign_id']?.toString(),
      title: (json['title'] ?? json['campaign_title'] ?? 'Untitled').toString(),
      description: (json['description'] ?? 'No description provided').toString(),
      goalAmount: parseDouble(json['funding_goal_f'] ?? json['funding_goal']),
      raisedAmount: parseDouble(json['total_contributions']),
      status: (json['status'] ?? 'active').toString(),
      durationMonths: parseInt(json['duration_d'] ?? json['duration_months'], defaultValue: 12),
      phaseProgress: 0.0, 
      fundraiserId: json['fundraiser_id']?.toString(),
      fundraiserName: json['fundraiser_name']?.toString() ?? 'Verified Fundraiser',
      backersCount: parseInt(json['backers_count']),
      daysLeft: parseInt(json['days_left']),
      category: (json['category_name'] ?? json['category'] ?? 'General').toString(),
      numPhases: parseInt(json['num_phases_p'] ?? json['num_phases']),
      coverImageUrl: json['cover_image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'funding_goal': goalAmount,
      'duration_months': durationMonths,
      'campaign_type': 'donation',
      'num_phases': numPhases,
    };
  }
}
