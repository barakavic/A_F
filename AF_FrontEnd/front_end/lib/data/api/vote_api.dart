import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/milestone.dart';

class VoteApi {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getPendingVotes() async {
    try {
      final response = await _apiClient.get('/votes/pending');
      final List<dynamic> data = response.data['milestones'];
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitVote({
    required String milestoneId,
    required String voteValue,
    required String signature,
    required String nonce,
  }) async {
    try {
      final response = await _apiClient.post(
        '/votes/submit',
        data: {
          'milestone_id': milestoneId,
          'vote_value': voteValue,
          'signature': signature,
          'nonce': nonce,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> waiveVotes({
    required String campaignId,
    required String signature,
    required String nonce,
  }) async {
    try {
      final response = await _apiClient.post(
        '/votes/waive',
        data: {
          'campaign_id': campaignId,
          'signature': signature,
          'nonce': nonce,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
