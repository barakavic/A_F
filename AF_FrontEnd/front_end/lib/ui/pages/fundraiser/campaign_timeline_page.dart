import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/project.dart';
import '../../../data/models/milestone.dart';
import '../../../data/repositories/campaign_repository.dart';
import 'milestone_detail_page.dart';
import 'submit_evidence_page.dart';

// Provider to fetch timeline for a specific campaign
final campaignTimelineProvider = FutureProvider.family<List<Milestone>, String>((ref, campaignId) async {
  final repo = CampaignRepository();
  return await repo.getCampaignTimeline(campaignId);
});

class CampaignTimelinePage extends ConsumerWidget {
  final Project project;

  const CampaignTimelinePage({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(campaignTimelineProvider(project.id!));

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text("Project Roadmap", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildProjectHeader()),
          timelineAsync.when(
            data: (milestones) => SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTimelineItem(context, milestones[index], index == milestones.length - 1),
                  childCount: milestones.length,
                ),
              ),
            ),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text("Error: $err"))),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "This roadmap is generated based on our governance algorithm to ensure transparency and accountability.",
            style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statItem("TOTAL BUDGET", "KES ${project.goalAmount.toInt()}"),
        _statItem("PHASES", project.numPhases.toString()),
        _statItem("STATUS", project.status.toUpperCase(), color: AppColors.primary),
      ],
    );
  }

  Widget _statItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, Milestone milestone, bool isLast) {
    bool isActive = milestone.status == 'active' || milestone.status == 'evidence_submitted';
    bool isCompleted = milestone.status == 'released' || milestone.status == 'approved';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : (isActive ? AppColors.primary : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(color: isCompleted ? Colors.green : (isActive ? AppColors.primary : Colors.grey.shade300), width: 2),
                ),
                child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.green : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Milestone ${milestone.milestoneNumber}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      _statusSmallBadge(milestone.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    milestone.description ?? "Submit proof of work to unlock funds for this phase.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _buildMilestoneDetails(milestone),
                  if (isActive) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SubmitEvidencePage(milestone: milestone)));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("SUBMIT EVIDENCE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneDetails(Milestone milestone) {
    final deadlineStr = milestone.targetDeadline != null ? DateFormat('MMM dd, yyyy').format(milestone.targetDeadline!) : 'TBD';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniDetail(Icons.calendar_today_outlined, deadlineStr),
        _miniDetail(Icons.payments_outlined, "KES ${milestone.releaseAmount.toInt()}"),
      ],
    );
  }

  Widget _miniDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _statusSmallBadge(String status) {
    Color color = Colors.grey;
    if (status == 'active') color = Colors.blue;
    if (status == 'released') color = Colors.green;
    if (status == 'evidence_submitted') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
