import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/contribution_service.dart';
import '../../data/models/wallet_stats.dart';

class ContributorWalletPage extends StatefulWidget {
  const ContributorWalletPage({super.key});

  @override
  State<ContributorWalletPage> createState() => _ContributorWalletPageState();
}

class _ContributorWalletPageState extends State<ContributorWalletPage> {
  final ContributionService _contributionService = ContributionService();
  ContributorWalletStats _walletStats = ContributorWalletStats.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletStats();
  }

  Future<void> _fetchWalletStats() async {
    try {
      final stats = await _contributionService.getWalletStats();
      if (mounted) {
        setState(() {
          _walletStats = stats;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wallet stats: $e');
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
            onPressed: () => _showReviewProofDetail(context),
            icon: const Icon(Icons.how_to_vote, size: 20),
            label: const Text("Review Proof and Vote"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Summary Stats
          _buildSummarySection(),
          
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text("View all milestone summaries", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ),
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

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallSummary("Ttl Disbursement", "KES 150k"),
              _buildSmallSummary("Ttl Spend", "KES 142k"),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Status: ", style: TextStyle(color: Colors.grey, fontSize: 12)),
              _buildStatusPill("Underspent", Colors.green),
              const SizedBox(width: 8),
              _buildStatusPill("Fully Used", Colors.blue.withOpacity(0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSummary(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showReviewProofDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReviewProofPage()),
    );
  }
}

class ReviewProofPage extends StatelessWidget {
  const ReviewProofPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Phase Review", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Phase #2", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const Text("Equipment Install", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Possible payout", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Text("KES 45,000", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            const Text("Phase Completion", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                value: 0.8,
                minHeight: 12,
                backgroundColor: Color(0xFFEEEEEE),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Milestone Budget
            _buildSectionHeader("Milestone Budget"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _buildBudgetItem("Solar Panels 5kW", "KES 30,000"),
                  _buildBudgetItem("Mounting Brackets", "KES 10,000"),
                  _buildBudgetItem("Wiring & Connectors", "KES 5,000"),
                  const Divider(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("KES 45,000", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Visual Proof
            _buildSectionHeader("Visual Proof"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildProofImage('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTCw3C5G0dkQgnt7XH-bjglpq7lBhzQ0uOZ4w&s')),
                const SizedBox(width: 12),
                Expanded(child: _buildProofImage('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRFd_dd5_OV72E2FVWIzny8iM9YbjYKDVtoIw&s')),
              ],
            ),
            
            const SizedBox(height: 48),
            
            // Decision Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Approve", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildBudgetItem(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProofImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(url, height: 120, fit: BoxFit.cover),
    );
  }
}
