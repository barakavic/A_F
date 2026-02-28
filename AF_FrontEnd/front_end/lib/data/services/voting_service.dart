import '../models/pending_milestone.dart';
import 'api_service.dart';
import '../../core/config/api_config.dart';

class VotingService {
  final ApiService _apiService = ApiService();

  Future<List<PendingMilestone>> getPendingVotes() async {
    try {
      print('[SERVICE] Requesting Pending Votes...');
      final response = await _apiService.get(ApiConfig.pendingVotes);
      print('[SERVICE] Pending Votes Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> milestones = response.data['milestones'];
        return milestones.map((json) => PendingMilestone.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('[SERVICE] Pending Votes Error: $e');
      return [];
    }
  }

  Future<bool> submitVote({
    required String milestoneId,
    required String voteValue,
    required String signature,
    required String nonce,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.submitVote,
        data: {
          'milestone_id': milestoneId,
          'vote_value': voteValue,
          'signature': signature,
          'nonce': nonce,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[SERVICE] Submit Vote Error: $e');
      return false;
    }
  }
}
