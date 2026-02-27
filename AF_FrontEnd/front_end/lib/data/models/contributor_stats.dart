class ContributorStats {
  final double totalPortfolioValue;
  final int activeInvestmentsCount;

  ContributorStats({
    required this.totalPortfolioValue,
    required this.activeInvestmentsCount,
  });

  factory ContributorStats.fromJson(Map<String, dynamic> json) {
    return ContributorStats(
      totalPortfolioValue: (json['total_portfolio_value'] as num).toDouble(),
      activeInvestmentsCount: json['active_investments_count'] as int,
    );
  }

  factory ContributorStats.empty() {
    return ContributorStats(
      totalPortfolioValue: 0.0,
      activeInvestmentsCount: 0,
    );
  }
}
