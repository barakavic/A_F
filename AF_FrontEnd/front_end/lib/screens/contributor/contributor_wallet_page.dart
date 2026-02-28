import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/contribution_service.dart';
import '../../data/services/voting_service.dart';
import '../../data/models/wallet_stats.dart';
import '../../data/models/pending_milestone.dart';
import 'phase_review_page.dart';

class ContributorWalletPage extends StatefulWidget {
  const ContributorWalletPage({super.key});

  @override
  State<ContributorWalletPage> createState() => _ContributorWalletPageState();
}

class _ContributorWalletPageState extends State<ContributorWalletPage> {
  final ContributionService _contributionService = ContributionService();
  final VotingService _votingService = VotingService();
  
  ContributorWalletStats _walletStats = ContributorWalletStats.empty();
  List<PendingMilestone> _pendingVotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _contributionService.getWalletStats(),
        _votingService.getPendingVotes(),
      ]);
      
      if (mounted) {
        setState(() {
          _walletStats = results[0] as ContributorWalletStats;
          _pendingVotes = results[1] as List<PendingMilestone>;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wallet data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'KES ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Project Balances",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Available vs Invested Stats
          Row(
            children: [
              Expanded(
                child: _buildBalanceStat(
                  "Available funds", 
                  _formatCurrency(_walletStats.availableFunds), 
                  Colors.blue
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBalanceStat(
                  "Invested funds", 
                  _formatCurrency(_walletStats.investedFunds), 
                  AppColors.primary
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Funding Ledger Section
          const Text(
            "Funding Ledger",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          
          _walletStats.ledger.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.history, color: Colors.grey.shade300, size: 48),
                      const SizedBox(height: 12),
                      const Text("No transactions yet", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _walletStats.ledger.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final entry = _walletStats.ledger[index];
                      final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(entry.date);
                      
                      return ListTile(
                        title: Text(entry.campaignTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: Text(
                          "-${_formatCurrency(entry.amount)}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)
                        ),
                      );
                    },
                  ),
                ),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: _pendingVotes.isEmpty ? null : () => _showReviewProofDetail(context),
            icon: Badge(
              label: Text(_pendingVotes.length.toString()),
              isLabelVisible: _pendingVotes.isNotEmpty,
              child: const Icon(Icons.how_to_vote, size: 20),
            ),
            label: Text(_pendingVotes.isEmpty ? "No Pending Votes" : "Review Proof and Vote (${_pendingVotes.length})"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _pendingVotes.isEmpty ? Colors.grey.shade200 : Colors.black87,
              foregroundColor: _pendingVotes.isEmpty ? Colors.grey : Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showReviewProofDetail(BuildContext context) async {
    if (_pendingVotes.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhaseReviewPage(milestone: _pendingVotes.first),
      ),
    );

    if (result == true) {
      // Refresh data if a vote was cast
      setState(() => _isLoading = true);
      _fetchData();
    }
  }
}
