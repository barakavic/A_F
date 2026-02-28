import '../models/contribution.dart';
import '../api/contribution_api.dart';

class ContributionRepository {
  final ContributionApi _api = ContributionApi();

  Future<List<UserContribution>> getMyContributions() async {
    try {
      final List<dynamic> data = await _api.getMyContributions();
      return data.map((json) => UserContribution.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> contribute({
    required String campaignId,
    required double amount,
  }) async {
    try {
      return await _api.createContribution(
        campaignId: campaignId,
        amount: amount,
      );
    } catch (e) {
      rethrow;
    }
  }
}
