import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/milestone.dart';
import '../submit_evidence_page.dart';
import 'milestone_status_badge.dart';
import '../voting_verdict_page.dart';

class MilestoneTimelineCard extends StatelessWidget {
  final Milestone milestone;
  final bool isLast;

  const MilestoneTimelineCard({
    super.key,
    required this.milestone,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = milestone.status == 'active' || 
                    milestone.status == 'voting_open' || 
                    milestone.status == 'evidence_submitted' || 
                    milestone.status == 'revision_submitted';
    bool isCompleted = milestone.status == 'released' || milestone.status == 'approved';
    bool isVotingOpen = milestone.status == 'voting_open';
    bool canSubmit = milestone.status == 'active' || milestone.status == 'rejected';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineGraphics(isActive, isCompleted),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: isVotingOpen 
                ? () => _showVoteStatus(context)
                : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVotingOpen
                        ? Colors.orange.withOpacity(0.5)
                        : (isActive ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade100),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isVotingOpen),
                    const SizedBox(height: 8),
                    Text(
                      milestone.description ?? "Submit proof of work to unlock funds for this phase.",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailsRow(),

                    if (isVotingOpen) 
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          "Tap to view voting verdict",
                          style: TextStyle(
                            color: Colors.orange.shade600, 
                            fontSize: 12, 
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    if (canSubmit) ...[
                      const SizedBox(height: 20),
                      _buildSubmitButton(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoteStatus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VotingVerdictPage(milestoneId: milestone.id),
      ),
    );
  }

  Widget _buildTimelineGraphics(bool isActive, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : (isActive ? AppColors.primary : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted ? Colors.green : (isActive ? AppColors.primary : Colors.grey.shade300), 
              width: 2,
            ),
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
    );
  }

  Widget _buildHeader(bool isVotingOpen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Milestone ${milestone.milestoneNumber}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Row(
          children: [
            MilestoneStatusBadge(status: milestone.status),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsRow() {
    final deadlineStr = milestone.targetDeadline != null 
        ? DateFormat('MMM dd, yyyy').format(milestone.targetDeadline!) 
        : 'TBD';
        
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
        Text(
          text, 
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => SubmitEvidencePage(milestone: milestone)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("SUBMIT EVIDENCE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
