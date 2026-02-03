import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'project_management_detail.dart';

class ActiveProjectsPage extends StatelessWidget {
  const ActiveProjectsPage({super.key});

  final List<Map<String, dynamic>> _projects = const [
    {
      'name': 'Solar for Schools',
      'status': 'Ongoing',
      'raised': 'KES 650,000',
      'progress': 0.65,
      'phase': 0.4,
      'nextAction': 'Upload Receipts',
    },
    {
      'name': 'Borehole Drilling',
      'status': 'Ongoing',
      'raised': 'KES 1,200,000',
      'progress': 0.85,
      'phase': 0.7,
      'nextAction': 'Verify Survey',
    },
    {
      'name': 'Community Library',
      'status': 'Completed',
      'raised': 'KES 500,000',
      'progress': 1.0,
      'phase': 1.0,
      'nextAction': 'Close Project',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _projects.length,
            itemBuilder: (context, index) {
              final project = _projects[index];
              return _buildProjectCard(context, project);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(BuildContext context, Map<String, dynamic> project) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectManagementDetail(projectName: project['name']),
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
                    project['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: project['status'] == 'Completed' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    project['status'],
                    style: TextStyle(
                      color: project['status'] == 'Completed' ? Colors.green : Colors.blue,
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
                _buildSmallInfo("Raised", project['raised']),
                const SizedBox(width: 24),
                _buildSmallInfo("Action", project['nextAction'], isAction: true),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Phase Progress", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("${(project['phase'] * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: project['phase'],
                minHeight: 6,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  project['phase'] == 1.0 ? Colors.green : Colors.orangeAccent,
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
