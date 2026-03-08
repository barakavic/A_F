import 'package:flutter/material.dart';

class ProjectFundraiserTrust extends StatelessWidget {
  final String? fundraiserName;

  const ProjectFundraiserTrust({super.key, this.fundraiserName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            child:
                Icon(Icons.person_outline, color: Colors.grey.shade400, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fundraiserName ?? 'Verified Fundraiser',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text("Verified Organization",
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey),
            onPressed: () {},
          )
        ],
      ),
    );
  }
}
