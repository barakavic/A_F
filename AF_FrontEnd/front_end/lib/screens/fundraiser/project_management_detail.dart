import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ProjectManagementDetail extends StatelessWidget {
  final String projectName;
  
  const ProjectManagementDetail({
    super.key, 
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          projectName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.account_circle_outlined, color: Colors.black), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Progress Section
            _buildSectionHeader("Financial Status"),
            const SizedBox(height: 12),
            _buildProgressCard(
              label: "Amount Raised / Goal",
              value: 0.65,
              trailing: "KES 650k / 1M",
              color: Colors.blueAccent,
            ),
            
            const SizedBox(height: 24),
            
            // Phase Progress Section
            _buildSectionHeader("Operational Progress"),
            const SizedBox(height: 12),
            _buildProgressCard(
              label: "Phase Completion",
              value: 0.40,
              trailing: "Phase 2 of 5",
              color: Colors.orangeAccent,
            ),

            const SizedBox(height: 32),

            // Proof Description Section
            _buildSectionHeader("Proof Description"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Current Phase: Foundation & Equipment Procurement",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We have successfully secured the site and completed the initial ground leveling. Equipment orders for solar arrays have been placed and are awaiting delivery confirmation.",
                    style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Update Journal"),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Upload Section
            _buildSectionHeader("Accountability"),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1), style: BorderStyle.solid),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        "Upload Supporting Docs",
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Text(
                        "PNG, PDF, or JPG up to 10MB",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Previous Milestones
            _buildSectionHeader("Milestone History"),
            const SizedBox(height: 12),
            _buildMilestoneItem("Site Survey Completed", "Jan 15, 2026", true),
            _buildMilestoneItem("Security Deposit Paid", "Jan 20, 2026", true),
            _buildMilestoneItem("Initial Permitting", "Jan 25, 2026", true),
            _buildMilestoneItem("Equipment Procurement", "In Progress", false),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  Widget _buildProgressCard({
    required String label, 
    required double value, 
    required String trailing,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(trailing, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(String title, String date, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.pending_outlined,
            color: isDone ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isDone ? FontWeight.normal : FontWeight.bold,
                color: isDone ? Colors.grey : Colors.black87,
              ),
            ),
          ),
          Text(
            date,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.home_filled, color: Colors.grey), onPressed: () {}),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business_center, color: AppColors.primary),
          ),
          IconButton(icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.grey), onPressed: () {}),
        ],
      ),
    );
  }
}
