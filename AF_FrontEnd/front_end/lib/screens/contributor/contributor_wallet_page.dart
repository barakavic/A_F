import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ContributorWalletPage extends StatelessWidget {
  const ContributorWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                child: _buildBalanceStat("Available funds", "KES 45,000", Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBalanceStat("Invested funds", "KES 200,000", AppColors.primary),
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final titles = ["Solar for Schools", "Borehole Drilling", "Vertical Farming", "Solar for Schools"];
                final amouts = ["-KES 5,000", "-KES 12,000", "-KES 2,500", "-KES 1,000"];
                final dates = ["Today, 2:30 PM", "Yesterday", "24 Jan 2026", "20 Jan 2026"];
                
                return ListTile(
                  title: Text(titles[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(dates[index], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Text(amouts[index], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
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
