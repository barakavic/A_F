import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'project_discovery_detail.dart';

class DiscoverProjectsPage extends StatelessWidget {
  const DiscoverProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildDiscoveryCard(
                context,
                'Solar Classrooms', 'EcoLearn Africa', 'KES 1M', '12 Days', 0.75, 'Technology',
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTCw3C5G0dkQgnt7XH-bjglpq7lBhzQ0uOZ4w&s',
              ),
              _buildDiscoveryCard(
                context,
                'Vertical Farming', 'GreenGrowth Labs', 'KES 5M', '4 Days', 0.45, 'AgriTech',
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRFd_dd5_OV72E2FVWIzny8iM9YbjYKDVtoIw&s',
              ),
              _buildDiscoveryCard(
                context,
                'Water Purification', 'KenyaClean Water', 'KES 500k', '20 Days', 0.30, 'Health',
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRRK-YX1_ZLSeAvPyF5EngnpHqxqhDzveANIw&s',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryCard(BuildContext context, String name, String fundraiser, String goal, String deadline, double progress, String cat, String img) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => ProjectDiscoveryDetail(projectName: name, fundraiserName: fundraiser))
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
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("by $fundraiser", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade100, color: AppColors.primary, minHeight: 6),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$cat • $deadline", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text(goal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
