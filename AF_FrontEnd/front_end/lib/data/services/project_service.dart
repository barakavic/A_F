import 'api_service.dart';
import '../../core/config/api_config.dart';
import '../models/project.dart';

class ProjectService {
  final ApiService _apiService = ApiService();

  // Fetch active projects (Discovery Feed)
  Future<List<Project>> getActiveProjects() async {
    try {
      final response = await _apiService.get(ApiConfig.campaigns); 
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Project.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('FETCH ERROR: $e');
      return [];
    }
  }

  // Fetch only my projects (Fundraiser Dashboard)
  Future<List<Project>> getMyProjects() async {
    try {
      final response = await _apiService.get(ApiConfig.myCampaigns); 
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Project.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('MY FETCH ERROR: $e');
      return [];
    }
  }

  // Create a new campaign
  Future<bool> createProject(Project project) async {
    try {
      final response = await _apiService.post(
        ApiConfig.campaigns,
        data: project.toJson(),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('CREATE ERROR: $e');
      return false;
    }
  }
}
