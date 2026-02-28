class FundraiserStats {
  final double totalRaised;
  final int activePhasesCount;
  final double availableBalance;
  final double escrowBalance;
  final int activeProjectsCount;

  FundraiserStats({
    required this.totalRaised,
    required this.activePhasesCount,
    required this.availableBalance,
    required this.escrowBalance,
    required this.activeProjectsCount,
  });

  factory FundraiserStats.fromJson(Map<String, dynamic> json) {
    return FundraiserStats(
      totalRaised: _parseDouble(json['total_raised']),
      activePhasesCount: _parseInt(json['active_phases_count']),
      availableBalance: _parseDouble(json['available_balance']),
      escrowBalance: _parseDouble(json['escrow_balance']),
      activeProjectsCount: _parseInt(json['active_projects_count']),
    );
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

  factory FundraiserStats.empty() {
    return FundraiserStats(
      totalRaised: 0.0, 
      activePhasesCount: 0,
      availableBalance: 0.0,
      escrowBalance: 0.0,
      activeProjectsCount: 0,
    );
  }
}
