import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/project.dart';
import 'package:provider/provider.dart' as legacy_provider;
import '../../../providers/project_provider.dart';
import '../../../providers/auth_provider.dart';
import '../campaign_creation/campaign_wizard_page.dart';
import 'campaign_timeline_page.dart';

class FundraiserDashboardPage extends ConsumerWidget {
  const FundraiserDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "ASCENT FIN",
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
          const CircleAvatar(radius: 16, backgroundColor: Color(0xFFEEEEEE), child: Icon(Icons.person, size: 20, color: Colors.grey)),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myProjectsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(context),
              const SizedBox(height: 32),
              _buildStatsGrid(),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Your Campaigns", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text("View All")),
                ],
              ),
              const SizedBox(height: 16),
              _buildCampaignList(ref),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CampaignWizardPage()));
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Create Campaign", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final authProvider = legacy_provider.Provider.of<AuthProvider>(context);
    final String displayName = authProvider.userDisplayName ?? "Fundraiser";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Welcome back,", style: TextStyle(fontSize: 16, color: Colors.grey)),
        Text(displayName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, color: Colors.green, size: 14),
              SizedBox(width: 4),
              Text("Verified Fundraiser", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Total Raised", "KES 1.2M", Icons.account_balance_wallet, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard("Active Phases", "3", Icons.track_changes, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCampaignList(WidgetRef ref) {
    final projectsAsync = ref.watch(myProjectsProvider);

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) return _buildEmptyState();
        return Column(
          children: projects.map((p) => _buildProjectCard(ref, p)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error loading campaigns: $err")),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.rocket_launch_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No campaigns yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("Launch your first project to start raising funds.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(WidgetRef ref, Project project) {
    final Color statusColor = _getStatusColor(project.status);

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CampaignTimelinePage(project: project)));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(project.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  _buildStatusBadge(project.status, statusColor),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCompactInfo("RAISED", "KES ${project.raisedAmount.toInt()}"),
                  _buildCompactInfo("GOAL", "KES ${project.goalAmount.toInt()}"),
                  _buildCompactInfo("DURATION", "${project.durationMonths}M"),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Funding Progress", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("${(project.raisedAmount / project.goalAmount * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (project.raisedAmount / project.goalAmount).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Color(0xFFF0F0F0),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildCompactInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft': return Colors.grey;
      case 'active': return Colors.blue;
      case 'funded': return Colors.green;
      case 'in_phases': return Colors.orange;
      case 'completed': return Colors.purple;
      default: return Colors.black;
    }
  }
}
