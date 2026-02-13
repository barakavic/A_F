import '../models/project.dart';
import 'api_client.dart';
import '../../core/config/api_config.dart';

class CampaignApi {
  final ApiClient _apiClient = ApiClient();

  /// Create a new campaign (Draft)
  Future<Project> createCampaign(Project project) async {
    try {
      final response = await _apiClient.post(ApiConfig.campaigns, data: project.toJson());
      return Project.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Launch a draft campaign to move it to 'active' status
  Future<Project> launchCampaign(String campaignId) async {
    try {
      final response = await _apiClient.post(ApiConfig.launchCampaign(campaignId));
      return Project.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get simplified progress metrics for the dashboard
  Future<Map<String, dynamic>> getCampaignProgress(String campaignId) async {
    try {
      final response = await _apiClient.get(ApiConfig.campaignProgress(campaignId));
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get the full timeline of milestones and events
  Future<List<dynamic>> getCampaignTimeline(String campaignId) async {
    try {
      final response = await _apiClient.get(ApiConfig.campaignTimeline(campaignId));
      return response.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a draft campaign
  Future<Project> cancelCampaign(String campaignId) async {
    try {
      final response = await _apiClient.post(ApiConfig.cancelCampaign(campaignId));
      return Project.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all public campaigns
  Future<List<Project>> getAllCampaigns() async {
    try {
      final response = await _apiClient.get(ApiConfig.campaigns);
      List<dynamic> data = response.data;
      return data.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
