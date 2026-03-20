import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/project_provider.dart';
import '../../data/models/fundraiser_stats.dart';

class FundraiserWalletPage extends ConsumerStatefulWidget {
  const FundraiserWalletPage({super.key});

  @override
  ConsumerState<FundraiserWalletPage> createState() => _FundraiserWalletPageState();
}

class _FundraiserWalletPageState extends ConsumerState<FundraiserWalletPage> {
  void _showWithdrawDialog(double availableBalance) {
    final TextEditingController amountController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Withdraw amount"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Available: KES ${NumberFormat('#,###.00').format(availableBalance)}", 
                   style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixText: "KES ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isProcessing ? null : () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0 || amount > availableBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid amount or insufficient balance"), backgroundColor: Colors.red),
                  );
                  return;
                }

                setDialogState(() => isProcessing = true);
                
                final success = await ref.read(projectServiceProvider).withdrawFunds(amount);
                
                if (mounted) {
                  if (success) {
                    ref.invalidate(fundraiserStatsProvider);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("KES ${amount.toStringAsFixed(2)} withdrawn to M-Pesa"), backgroundColor: Colors.green),
                    );
                  } else {
                    setDialogState(() => isProcessing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Withdrawal unsuccessful. Please try again."), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isProcessing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(fundraiserStatsProvider);

    return statsAsync.when(
      data: (stats) => _buildContent(context, stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error loading wallet: $err")),
    );
  }

  Widget _buildContent(BuildContext context, FundraiserStats stats) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(fundraiserStatsProvider);
        return await ref.read(fundraiserStatsProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), 
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Project Balances",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            _buildBalancesCard(stats, currencyFormat),
            
            const SizedBox(height: 32),
            
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: ElevatedButton(
                  onPressed: stats.availableBalance > 0 
                      ? () => _showWithdrawDialog(stats.availableBalance)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Withdraw Funds"),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Transaction List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.filter_list, color: Colors.grey.shade400, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildLedger(stats),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBalancesCard(FundraiserStats stats, NumberFormat format) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Available Balance", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(format.format(stats.availableBalance), 
               style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          Row(
            children: [
              _buildSimpleStat("Escrow", format.format(stats.escrowBalance)),
              const SizedBox(width: 32),
              _buildSimpleStat("Active Projects", stats.activeProjectsCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
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
        itemCount: stats.totalWithdrawn > 0 ? 3 : 2, 
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final now = DateTime.now();
          final String today = DateFormat('dd.MM.yy').format(now);

          final transactions = [
            if (stats.totalWithdrawn > 0)
              {
                "title": "Total Withdrawn", 
                "amt": "-KES ${NumberFormat('#,###').format(stats.totalWithdrawn)}", 
                "date": today
              },
            {
              "title": "Escrow Payout: Phase 1", 
              "amt": "+KES ${NumberFormat('#,###').format(stats.availableBalance + stats.totalWithdrawn)}", 
              "date": "15.03.24"
            },
            {
              "title": "Initial Funding", 
              "amt": "+KES ${NumberFormat('#,###').format(stats.totalRaised)}", 
              "date": "10.03.24"
            },
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
            subtitle: Text(item['date']!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            trailing: Text(item['amt']!, style: TextStyle(fontWeight: FontWeight.bold, color: isNegative ? Colors.black87 : Colors.green)),
          );
        },
      ),
    );
  }
}
