import 'package:front_end/data/models/contribution.dart';

class WalletLedgerEntry {
  final String id;
  final String campaignTitle;
  final double amount;
  final String type;
  final String status;
  final DateTime date;

  WalletLedgerEntry({
    required this.id,
    required this.campaignTitle,
    required this.amount,
    required this.type,
    required this.status,
    required this.date,
  });

  factory WalletLedgerEntry.fromJson(Map<String, dynamic> json) {
    return WalletLedgerEntry(
      id: json['id'],
      campaignTitle: json['campaign_title'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      status: json['status'],
      date: DateTime.parse(json['date']),
    );
  }
}

class ContributorWalletStats {
  final double availableFunds;
  final double investedFunds;
  final List<WalletLedgerEntry> ledger;

  ContributorWalletStats({
    required this.availableFunds,
    required this.investedFunds,
    required this.ledger,
  });

  factory ContributorWalletStats.fromJson(Map<String, dynamic> json) {
    return ContributorWalletStats(
      availableFunds: (json['available_funds'] as num).toDouble(),
      investedFunds: (json['invested_funds'] as num).toDouble(),
      ledger: (json['ledger'] as List)
          .map((e) => WalletLedgerEntry.fromJson(e))
          .toList(),
    );
  }

  factory ContributorWalletStats.empty() {
    return ContributorWalletStats(
      availableFunds: 0.0,
      investedFunds: 0.0,
      ledger: [],
    );
  }
}
