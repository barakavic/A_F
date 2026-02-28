import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/project_provider.dart';
import '../../data/models/fundraiser_stats.dart';

class FundraiserWalletPage extends ConsumerWidget {
  const FundraiserWalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(fundraiserStatsProvider);

    return statsAsync.when(
      data: (stats) => _buildContent(context, stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error loading wallet: $err")),
    );
  }

  Widget _buildContent(BuildContext context, FundraiserStats stats) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

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
          _buildBalancesCard(stats, currencyFormat),
          
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
          
          // Ledger
          _buildLedger(stats),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBalancesCard(FundraiserStats stats, NumberFormat format) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Available Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            format.format(stats.availableBalance), 
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSmallBalance("Escrow (Locked)", format.format(stats.escrowBalance)),
              const SizedBox(width: 40),
              _buildSmallBalance("Projects", "${stats.activeProjectsCount} Active"),
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

  Widget _buildLedger(FundraiserStats stats) {
    if (stats.totalRaised == 0 && stats.availableBalance == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.history, color: Colors.grey.shade300, size: 48),
            const SizedBox(height: 16),
            const Text("No transactions yet", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
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
        itemCount: 2, // Dummy entries for now if there's balance but no ledger implementation
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final transactions = [
            {"title": "Escrow Payout: Phase 1", "amt": "+KES ${stats.availableBalance.toInt()}", "status": "Completed", "date": "Recent"},
            {"title": "Initial Funding", "amt": "+KES ${stats.totalRaised.toInt()}", "status": "In Escrow", "date": "Recent"},
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
    );
  }
}
