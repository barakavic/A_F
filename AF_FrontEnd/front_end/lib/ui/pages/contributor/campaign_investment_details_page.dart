import 'package:flutter/material.dart';
import 'package:front_end/core/constants/app_colors.dart';
import 'package:front_end/data/models/campaign_details.dart';
import 'package:front_end/data/models/milestone.dart';
import 'package:front_end/data/repositories/campaign_repository.dart';

class CampaignInvestmentDetailsPage extends StatefulWidget {
  final String campaignId;
  final double investedAmount;

  const CampaignInvestmentDetailsPage({
    super.key,
    required this.campaignId,
    required this.investedAmount,
  });

  @override
  State<CampaignInvestmentDetailsPage> createState() => _CampaignInvestmentDetailsPageState();
}

class _CampaignInvestmentDetailsPageState extends State<CampaignInvestmentDetailsPage> {
  final CampaignRepository _repository = CampaignRepository();
  bool _isLoading = true;
  CampaignDetails? _details;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _repository.getCampaignDetails(widget.campaignId);
      setState(() {
        _details = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text("Campaign Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildContentView(),
    );
  }

  Widget _buildContentView() {
    final details = _details!;
    final completedMilestones = details.milestones.where((m) => m.status == 'approved' || m.status == 'released').length;
    final totalMilestones = details.milestones.length;
    final progress = totalMilestones > 0 ? completedMilestones / totalMilestones : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCampaignHeader(details),
          const SizedBox(height: 32),
          _buildInvestmentSummary(progress),
          const SizedBox(height: 32),
          _buildMilestoneTimeline(details.milestones),
          const SizedBox(height: 32),
          if (details.status == 'failed') _buildRefundSection(),
        ],
      ),
    );
  }

  Widget _buildCampaignHeader(CampaignDetails details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(details.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                details.status.toUpperCase(),
                style: TextStyle(color: _getStatusColor(details.status), fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            Text(
              "Founded: ${_formatDate(details.createdAt)}",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          details.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          details.description,
          style: TextStyle(color: Colors.grey.shade600, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildInvestmentSummary(double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Your Investment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat("Pledged Amount", "KES ${widget.investedAmount.toStringAsFixed(0)}"),
              _buildStat("Funds in Escrow", "KES ${(widget.investedAmount * (1 - progress)).toStringAsFixed(0)}"),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Project Progress", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${(progress * 100).toInt()}% Complete", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text("Next Stage: Milestone ${_details!.currentMilestoneNumber + 1}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildMilestoneTimeline(List<Milestone> milestones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Roadmap & Milestones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: milestones.length,
          itemBuilder: (context, index) {
            return _buildMilestoneItem(milestones[index], index == milestones.length - 1);
          },
        ),
      ],
    );
  }

  Widget _buildMilestoneItem(Milestone milestone, bool isLast) {
    bool isCompleted = milestone.status == 'approved' || milestone.status == 'released';
    bool isActive = milestone.status == 'active' || milestone.status == 'voting_open';

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primary : isActive ? Colors.orange : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? AppColors.primary : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Milestone ${milestone.milestoneNumber}",
                        style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted || isActive ? Colors.black : Colors.grey),
                      ),
                      if (milestone.targetDeadline != null)
                        Text(
                          _formatDate(milestone.targetDeadline!),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    milestone.description ?? "No description provided",
                    style: TextStyle(fontSize: 13, color: isCompleted || isActive ? Colors.grey.shade600 : Colors.grey.shade400),
                  ),
                  if (isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text("IN PROGRESS", style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
          const SizedBox(height: 16),
          const Text("Project Terminated", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
          const SizedBox(height: 8),
          const Text(
            "This project failed to meet its milestone targets. You can claim your remaining funds from escrow.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Refund request submitted successfully!")));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Claim KES 4,500 Refund"),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.green;
      case 'in_phases': return Colors.blue;
      case 'funded': return Colors.orange;
      case 'completed': return Colors.purple;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Error Loading Details", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            TextButton(onPressed: _fetchDetails, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}
