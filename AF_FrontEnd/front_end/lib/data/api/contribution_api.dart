import '../services/api_service.dart';
import '../../core/config/api_config.dart';

class ContributionApi {
  final ApiService _apiClient = ApiService();

  /// Create a new contribution
  Future<Map<String, dynamic>> createContribution({
    required String campaignId,
    required double amount,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.contributions,
        data: {
          'campaign_id': campaignId,
          'amount': amount,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get contributions for the current user
  Future<List<dynamic>> getMyContributions() async {
    try {
      final response = await _apiClient.get(ApiConfig.myContributions);
      return response.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
