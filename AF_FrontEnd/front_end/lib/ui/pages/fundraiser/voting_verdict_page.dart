import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/campaign_repository.dart';

final voteStatusProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, milestoneId) async {
  return await CampaignRepository().getVoteStatus(milestoneId);
});

class VotingVerdictPage extends ConsumerWidget {
  final String milestoneId;
  const VotingVerdictPage({super.key, required this.milestoneId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(voteStatusProvider(milestoneId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Voting Verdict", style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (data) => _buildBody(data),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> data) {
    final int votesCast = data['votes_cast'] ?? data['total_votes'] ?? 0;
    final int totalVoters = data['total_eligible_voters'] ?? data['quorum'] ?? 0;
    final double yesPct = (data['yes_percentage'] ?? 0.0).toDouble();
    final bool likelyPass = yesPct >= 75;

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${yesPct.toStringAsFixed(0)}%",
            style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: likelyPass ? Colors.green : Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(
            likelyPass ? "ABOVE THRESHOLD" : "BELOW THRESHOLD",
            style: TextStyle(fontWeight: FontWeight.bold, color: likelyPass ? Colors.green : Colors.orange, letterSpacing: 1),
          ),
          const SizedBox(height: 48),
          LinearProgressIndicator(
            value: yesPct / 100,
            backgroundColor: Colors.grey.shade100,
            color: likelyPass ? Colors.green : Colors.orange,
            minHeight: 8,
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat("YES", "${data['yes_votes'] ?? data['yes'] ?? 0}"),
              _stat("NO", "${data['no_votes'] ?? data['no'] ?? 0}"),
              _stat("TOTAL", "$votesCast/$totalVoters"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
