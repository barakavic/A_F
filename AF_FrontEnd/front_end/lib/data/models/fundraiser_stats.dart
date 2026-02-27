class FundraiserStats {
  final double totalRaised;
  final int activePhasesCount;

  FundraiserStats({
    required this.totalRaised,
    required this.activePhasesCount,
  });

  factory FundraiserStats.fromJson(Map<String, dynamic> json) {
    return FundraiserStats(
      totalRaised: (json['total_raised'] as num).toDouble(),
      activePhasesCount: json['active_phases_count'] as int,
    );
  }

  factory FundraiserStats.empty() {
    return FundraiserStats(totalRaised: 0.0, activePhasesCount: 0);
  }
}
