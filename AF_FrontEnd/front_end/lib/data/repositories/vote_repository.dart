import '../api/vote_api.dart';

class PendingVote {
  final String milestoneId;
  final int milestoneNumber;
  final String description;
  final String campaignTitle;
  final String campaignId;
  final DateTime votingEndDate;
  final double releaseAmount;
  final String? evidenceDescription;

  PendingVote({
    required this.milestoneId,
    required this.milestoneNumber,
    required this.description,
    required this.campaignTitle,
    required this.campaignId,
    required this.votingEndDate,
    required this.releaseAmount,
    this.evidenceDescription,
  });

  factory PendingVote.fromJson(Map<String, dynamic> json) {
    return PendingVote(
      milestoneId: json['milestone_id'],
      milestoneNumber: json['milestone_number'],
      description: json['description'],
      campaignTitle: json['campaign_title'],
      campaignId: json['campaign_id'],
      votingEndDate: DateTime.parse(json['voting_end_date']),
      releaseAmount: json['release_amount'].toDouble(),
      evidenceDescription: json['evidence_description'],
    );
  }
}

class VoteRepository {
  final VoteApi _voteApi = VoteApi();

  Future<List<PendingVote>> getPendingVotes() async {
    final List<Map<String, dynamic>> data = await _voteApi.getPendingVotes();
    return data.map((e) => PendingVote.fromJson(e)).toList();
  }

  Future<bool> submitVote({
    required String milestoneId,
    required String voteValue,
    required String signature,
    required String nonce,
  }) async {
    try {
      final result = await _voteApi.submitVote(
        milestoneId: milestoneId,
        voteValue: voteValue,
        signature: signature,
        nonce: nonce,
      );
      return result['status'] == 'success';
    } catch (e) {
      return false;
    }
  }
}
