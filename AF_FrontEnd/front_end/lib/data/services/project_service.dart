import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/project.dart';

class ProjectService {
  final ApiService _apiService = ApiService();

  // Fetch active projects
  Future<List<Project>> getActiveProjects() async {
    try {
      final response = await _apiService.get('/campaigns/active'); 
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Project.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching projects: $e'); // In production, use logging
      return [];
    }
  }

  // Create a new campaign
  Future<bool> createProject(Project project) async {
    try {
      final response = await _apiService.post(
        '/campaigns/',
        data: project.toJson(),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error creating project: $e');
      return false;
    }
  }
}
