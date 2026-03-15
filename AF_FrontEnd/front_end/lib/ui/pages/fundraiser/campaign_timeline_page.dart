import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/project.dart';
import '../../../data/models/milestone.dart';
import '../../../data/repositories/campaign_repository.dart';
import './widgets/active_project_header.dart';
import './widgets/milestone_timeline_card.dart';

// Provider to fetch timeline for a specific campaign
final campaignTimelineProvider = FutureProvider.family<List<Milestone>, String>((ref, campaignId) async {
  final repo = CampaignRepository();
  return await repo.getCampaignTimeline(campaignId);
});

class CampaignTimelinePage extends ConsumerStatefulWidget {
  final Project project;

  const CampaignTimelinePage({super.key, required this.project});

  @override
  ConsumerState<CampaignTimelinePage> createState() => _CampaignTimelinePageState();
}

class _CampaignTimelinePageState extends ConsumerState<CampaignTimelinePage> {
  void _onRefresh() {
    ref.invalidate(campaignTimelineProvider(widget.project.id!));
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(campaignTimelineProvider(widget.project.id!));

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), 
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Project Roadmap", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _onRefresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Ensure it's scrollable even when short
          slivers: [
            SliverToBoxAdapter(child: ActiveProjectHeader(project: widget.project)),
            timelineAsync.when(
              data: (milestones) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final milestone = milestones[index];
                      return MilestoneTimelineCard(
                        milestone: milestone,
                        isLast: index == milestones.length - 1,
                      );
                    },
                    childCount: milestones.length,
                  ),
                ),
              ),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text("Error loading roadmap: $err")),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildSimulateButton(),
    );
  }

  Widget? _buildSimulateButton() {
    if (widget.project.status.toLowerCase() != 'in_phases') return null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      child: FloatingActionButton.extended(
        onPressed: () async {
          final repo = CampaignRepository();
          try {
            final result = await repo.simulateAdvance(widget.project.id!);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? "Phase Advanced!"),
                  backgroundColor: result['status'] == 'success' ? Colors.green : Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _onRefresh();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Simulation Error: $e"), 
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        backgroundColor: Colors.black,
        label: const Text(
          "SIMULATE PROGRESS (SKIP WAIT)",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        icon: const Icon(Icons.flash_on, color: Colors.amber),
      ),
    );
  }
}
