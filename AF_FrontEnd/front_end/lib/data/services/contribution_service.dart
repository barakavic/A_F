import '../models/contributor_stats.dart';
import '../models/contribution.dart';
import 'api_service.dart';
import '../../core/config/api_config.dart';

class ContributionService {
  final ApiService _apiService = ApiService();

  Future<ContributorStats> getContributorStats() async {
    try {
      print('[SERVICE] Requesting Contributor Stats...');
      final response = await _apiService.get(ApiConfig.contributorStats);
      print('[SERVICE] Stats Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return ContributorStats.fromJson(response.data);
      }
      return ContributorStats.empty();
    } catch (e) {
      print('[SERVICE] Stats Error: $e');
      return ContributorStats.empty();
    }
  }

  Future<List<UserContribution>> getMyContributions() async {
    try {
      print('[SERVICE] Requesting My Contributions...');
      final response = await _apiService.get(ApiConfig.myContributions);
      print('[SERVICE] Contributions Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        if (response.data is! List) {
          print('[SERVICE] Warning: Contributions response is not a list: ${response.data}');
          return [];
        }
        return (response.data as List)
            .map((json) => UserContribution.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('[SERVICE] Contributions Error: $e');
      return [];
    }
  }
}
