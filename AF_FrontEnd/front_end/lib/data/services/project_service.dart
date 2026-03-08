import 'package:dio/dio.dart';
import 'api_service.dart';
import '../../core/config/api_config.dart';
import '../models/project.dart';
import '../models/fundraiser_stats.dart';

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

  // Fetch a single project by ID (For Pull-to-Refresh on details page)
  Future<Project?> getProjectById(String id) async {
    try {
      final response = await _apiService.get('${ApiConfig.campaigns}/$id');
      if (response.statusCode == 200) {
        return Project.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('FETCH SINGLE ERROR: $e');
      return null;
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

  // Create a new campaign, returns the campaign ID if successful
  Future<String?> createProject(Project project) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.campaigns}/',
        data: project.toJson(),
      );
      print('CREATE RESPONSE: ${response.statusCode} | ${response.data}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['campaign_id']?.toString();
      }
      return null;
    } catch (e) {
      print('CREATE ERROR: $e');
      rethrow;
    }
  }

  // Launch a draft campaign
  Future<bool> launchProject(String campaignId) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.campaigns}/$campaignId/launch',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('LAUNCH ERROR: $e');
      return false;
    }
  }

  // Upload Cover Image
  Future<bool> uploadCoverImage(String campaignId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });

      final String uploadUrl = '${ApiConfig.campaigns}/$campaignId/cover-image'.replaceAll('//', '/').replaceFirst('https:/', 'https://').replaceFirst('http:/', 'http://');
      print('UPLOADING TO: $uploadUrl');

      final response = await _apiService.postMultipart(
        uploadUrl,
        data: formData,
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('COVER UPLOAD ERROR: $e');
      return false;
    }
  }

  // Fetch fundraiser statistics
  Future<FundraiserStats> getFundraiserStats() async {
    try {
      final response = await _apiService.get(ApiConfig.fundraiserStats);
      if (response.statusCode == 200) {
        return FundraiserStats.fromJson(response.data);
      }
      return FundraiserStats.empty();
    } catch (e) {
      print('STATS FETCH ERROR: $e');
      return FundraiserStats.empty();
    }
  }
}
