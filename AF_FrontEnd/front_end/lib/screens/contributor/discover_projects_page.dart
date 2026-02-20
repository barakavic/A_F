import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/project_provider.dart';
import '../../data/models/project.dart';
import 'project_discovery_detail.dart';

class DiscoverProjectsPage extends ConsumerWidget {
  const DiscoverProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(activeProjectsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Discover Projects", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Support high-impact initiatives today", style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
        Expanded(
          child: projectsAsync.when(
            data: (projects) => RefreshIndicator(
              onRefresh: () => ref.refresh(activeProjectsProvider.future),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return _buildDiscoveryCard(
                    context,
                    project,
                  );
                },
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error: $err")),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryCard(BuildContext context, Project project) {
    // Default image if none provided
    const String img = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTCw3C5G0dkQgnt7XH-bjglpq7lBhzQ0uOZ4w&s';
    final double progress = project.raisedAmount / (project.goalAmount > 0 ? project.goalAmount : 1.0);
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => ProjectDiscoveryDetail(project: project))
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(img, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("by ${project.fundraiserId ?? 'Verified Fundraiser'}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress > 1.0 ? 1.0 : progress, 
                    backgroundColor: Colors.grey.shade100, 
                    color: AppColors.primary, 
                    minHeight: 6
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${project.durationMonths} Months • ${project.status.toUpperCase()}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text("Goal: KES ${project.goalAmount.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
