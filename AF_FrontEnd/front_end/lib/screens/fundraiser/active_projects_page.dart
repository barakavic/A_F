import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/project.dart';
import '../../providers/project_provider.dart';
import 'project_management_detail.dart';
import '../../ui/pages/campaign_creation/campaign_wizard_page.dart';
import 'widgets/create_campaign_form.dart';
import '../../ui/pages/fundraiser/campaign_timeline_page.dart';

class ActiveProjectsPage extends ConsumerStatefulWidget {
  const ActiveProjectsPage({super.key});

  @override
  ConsumerState<ActiveProjectsPage> createState() => ActiveProjectsPageState();
}

class ActiveProjectsPageState extends ConsumerState<ActiveProjectsPage> {
  void _refreshProjects() {
    ref.invalidate(myProjectsProvider);
  }

  void showCreateCampaignSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CampaignWizardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Active Projects",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Manage your performance and impact",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async => _refreshProjects(),
          child: ref.watch(myProjectsProvider).when(
                data: (projects) {
                  if (projects.isEmpty) return _buildEmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      return _buildProjectCard(context, projects[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Failed to load projects"),
                      TextButton(
                        onPressed: _refreshProjects,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No active campaigns", style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampaignTimelinePage(project: project),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: project.status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    project.status.toUpperCase(),
                    style: TextStyle(
                      color: project.status == 'completed' ? Colors.green : Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSmallInfo("Raised", "KES ${project.raisedAmount.toInt()}"),
                const SizedBox(width: 24),
                _buildSmallInfo("Goal", "KES ${project.goalAmount.toInt()}", isAction: true),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Phase Progress", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("${(project.phaseProgress * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: project.phaseProgress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  project.phaseProgress == 1.0 ? Colors.green : Colors.orangeAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInfo(String label, String value, {bool isAction = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isAction ? AppColors.primary : Colors.black87,
          ),
        ),
      ],
    );
  }
}
