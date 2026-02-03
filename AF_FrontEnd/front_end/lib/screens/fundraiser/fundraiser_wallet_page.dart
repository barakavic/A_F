import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FundraiserWalletPage extends StatelessWidget {
  const FundraiserWalletPage({super.key});

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
          
          // Balances Card
          _buildBalancesCard(),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Deposit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download_outlined, size: 20),
                  label: const Text("Withdraw"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Transaction List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Transaction List",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.filter_list, color: Colors.grey.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          
          // Scrollable Ledger
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final transactions = [
                  {"title": "Withdrawal to M-Pesa", "amt": "-KES 12,000", "status": "Completed", "date": "Today"},
                  {"title": "Escrow Payout: Phase 1", "amt": "+KES 45,000", "status": "Completed", "date": "Yesterday"},
                  {"title": "M-Pesa Deposit", "amt": "+KES 2,000", "status": "Completed", "date": "24 Jan"},
                  {"title": "Platform Fee", "amt": "-KES 450", "status": "Completed", "date": "24 Jan"},
                  {"title": "Escrow Payout: Final", "amt": "+KES 120,000", "status": "Completed", "date": "15 Jan"},
                  {"title": "Withdrawal to Bank", "amt": "-KES 50,000", "status": "Processing", "date": "10 Jan"},
                ];
                
                final item = transactions[index];
                final isNegative = item['amt']!.startsWith('-');
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isNegative ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isNegative ? Icons.north_east : Icons.south_west,
                      color: isNegative ? Colors.redAccent : Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("${item['date']} • ${item['status']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  trailing: Text(item['amt']!, style: TextStyle(fontWeight: FontWeight.bold, color: isNegative ? Colors.black87 : Colors.green)),
                );
              },
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Create Project Footer
          Center(
            child: Column(
              children: [
                const Text("Create Project:", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {},
                  backgroundColor: AppColors.primary,
                  elevation: 2,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBalancesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade800, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Available Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          const Text("KES 84,250.00", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSmallBalance("Escrow (Locked)", "KES 245K"),
              const SizedBox(width: 40),
              _buildSmallBalance("Projects", "3 Active"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBalance(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
