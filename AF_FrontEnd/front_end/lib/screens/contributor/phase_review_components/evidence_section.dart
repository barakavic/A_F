import 'package:flutter/material.dart';
import '../../../data/models/pending_milestone.dart';
import '../../../core/config/api_config.dart';

class EvidenceSection extends StatelessWidget {
  final PendingMilestone milestone;

  const EvidenceSection({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Visual Proof of Work"),
        const SizedBox(height: 12),
        if (milestone.evidenceDescription != null && milestone.evidenceDescription!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              milestone.evidenceDescription!,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        if (milestone.evidenceImageUrls.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: milestone.evidenceImageUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildProofImage(milestone.evidenceImageUrls[index]),
                );
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
            ),
            child: const Center(
              child: Text("No visual evidence provided.", style: TextStyle(color: Colors.grey)),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildProofImage(String url) {
    if (!url.startsWith('http')) {
      url = '${ApiConfig.rootUrl}/$url';
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(url, height: 120, width: 200, fit: BoxFit.cover),
    );
  }
}
