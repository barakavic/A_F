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
      amount: _parseDouble(json['amount']),
      type: json['type'],
      status: json['status'],
      date: DateTime.parse(json['date']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
    var ledgerData = json['ledger'];
    List<WalletLedgerEntry> ledgerList = [];
    if (ledgerData is List) {
      ledgerList = ledgerData.map((e) => WalletLedgerEntry.fromJson(e)).toList();
    }
    
    return ContributorWalletStats(
      availableFunds: _parseDouble(json['available_funds']),
      investedFunds: _parseDouble(json['invested_funds']),
      ledger: ledgerList,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory ContributorWalletStats.empty() {
    return ContributorWalletStats(
      availableFunds: 0.0,
      investedFunds: 0.0,
      ledger: [],
    );
  }
}
