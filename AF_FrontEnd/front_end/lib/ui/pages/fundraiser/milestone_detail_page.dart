import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/milestone.dart';
import 'submit_evidence_page.dart';

class MilestoneDetailPage extends StatelessWidget {
  final Milestone milestone;

  const MilestoneDetailPage({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text("Milestone ${milestone.milestoneNumber}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 32),
            const Text("Phase Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              milestone.description ?? "No description provided for this work phase.",
              style: TextStyle(color: Colors.grey.shade700, height: 1.6),
            ),
            const SizedBox(height: 32),
            _buildInfoGrid(),
            const SizedBox(height: 40),
            if (milestone.status == 'active') _buildActionRequired(),
            if (milestone.status == 'evidence_submitted' || milestone.status == 'voting_open') _buildEvidencePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _statusIcon(),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Current Status", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(milestone.status.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusIcon() {
    IconData icon = Icons.timer_outlined;
    Color color = Colors.blue;
    if (milestone.status == 'released') { icon = Icons.check_circle; color = Colors.green; }
    if (milestone.status == 'evidence_submitted') { icon = Icons.hourglass_top; color = Colors.orange; }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildInfoGrid() {
    final deadline = milestone.targetDeadline != null ? DateFormat('MMM dd, yyyy').format(milestone.targetDeadline!) : 'None';
    return Row(
      children: [
        Expanded(child: _infoCard("Release Amount", "KES ${milestone.releaseAmount.toInt()}", Icons.payments_outlined)),
        const SizedBox(width: 16),
        Expanded(child: _infoCard("Target Date", deadline, Icons.calendar_today_outlined)),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionRequired() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary, size: 32),
            const SizedBox(height: 16),
            const Text("Attention Required", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              "You need to provide proof of completion to unlock the funds for this phase.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SubmitEvidencePage(milestone: milestone)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text("SUBMIT PROOF OF WORK", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidencePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Submitted Evidence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: NetworkImage("https://via.placeholder.com/400x200?text=Milestone+Evidence+Preview"),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(begin: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent]),
            ),
            child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48)),
          ),
        ),
      ],
    );
  }
}
