class ContributorStats {
  final double totalPortfolioValue;
  final int activeInvestmentsCount;

  ContributorStats({
    required this.totalPortfolioValue,
    required this.activeInvestmentsCount,
  });

  factory ContributorStats.fromJson(Map<String, dynamic> json) {
    return ContributorStats(
      totalPortfolioValue: _parseDouble(json['total_portfolio_value']),
      activeInvestmentsCount: json['active_investments_count'] as int,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory ContributorStats.empty() {
    return ContributorStats(
      totalPortfolioValue: 0.0,
      activeInvestmentsCount: 0,
    );
  }
}
