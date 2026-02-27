import '../models/contributor_stats.dart';
import 'api_service.dart';
import '../../core/config/api_config.dart';

class ContributionService {
  final ApiService _apiService = ApiService();

  Future<ContributorStats> getContributorStats() async {
    try {
      final response = await _apiService.get(ApiConfig.contributorStats);
      if (response.statusCode == 200) {
        return ContributorStats.fromJson(response.data);
      }
      return ContributorStats.empty();
    } catch (e) {
      print('Error fetching contributor stats: $e');
      return ContributorStats.empty();
    }
  }
}
