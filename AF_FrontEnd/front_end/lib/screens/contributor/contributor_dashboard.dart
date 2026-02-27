import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'discover_projects_page.dart';
import 'contributor_wallet_page.dart';
import '../../ui/pages/contributor/pending_votes_page.dart';
import '../../ui/pages/contributor/portfolio_page.dart';
import '../../data/services/contribution_service.dart';
import '../../data/models/contributor_stats.dart';
import 'package:intl/intl.dart';

class ContributorDashboard extends StatefulWidget {
  const ContributorDashboard({super.key});

  @override
  State<ContributorDashboard> createState() => _ContributorDashboardState();
}

class _ContributorDashboardState extends State<ContributorDashboard> {
  int _selectedIndex = 0;
  final ContributionService _contributionService = ContributionService();
  ContributorStats _stats = ContributorStats.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final stats = await _contributionService.getContributorStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ASCENT',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.account_circle_outlined, color: Colors.black), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildPortfolioHome(),   
          const DiscoverProjectsPage(), 
          const ContributorWalletPage(), // Linked Wallet Page
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPortfolioHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortfolioCard(),
          const SizedBox(height: 24),
          _buildActionCard(context),
          const SizedBox(height: 32),
          const Text(
            'Active Investments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildContributionListItem('Solar for Schools', 'Renewable Energy', 0.75, 'KES 15K'),
          _buildContributionListItem('Vertical Farming', 'AgriTech', 0.40, 'KES 5K'),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PortfolioPage()));
      },
      child: Container(
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
            const Text('Total Portfolio Value', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: 'KES ', decimalDigits: 2).format(_stats.totalPortfolioValue),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(label: 'Investments', value: _stats.activeInvestmentsCount.toString()),
                // ROI and Impact removed per user request
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(0, Icons.home_rounded),
          _navIcon(1, Icons.trending_up_rounded), 
          _navIcon(2, Icons.account_balance_wallet_outlined),
        ],
      ),
    );
  }

  Widget _navIcon(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 28),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PendingVotesPage()));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.how_to_vote, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Action Required", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                  Text(
                    "You have pending milestones to review and vote on.",
                    style: TextStyle(color: Colors.orange.shade900, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionListItem(String title, String category, double progress, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(category, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ])),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
    ]);
  }
}
