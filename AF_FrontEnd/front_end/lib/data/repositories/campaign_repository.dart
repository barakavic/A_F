import 'dart:io';
import '../api/campaign_api.dart';
import '../api/milestone_api.dart';
import '../models/project.dart';
import '../models/milestone.dart';

class CampaignRepository {
  final CampaignApi _campaignApi = CampaignApi();
  final MilestoneApi _milestoneApi = MilestoneApi();

  
  Future<List<Project>> getDiscoveryCampaigns() async {
    return await _campaignApi.getAllCampaigns();
  }

  Future<Project> createNewCampaign(Project project) async {
    return await _campaignApi.createCampaign(project);
  }

  Future<Project> launchCampaign(String campaignId) async {
    return await _campaignApi.launchCampaign(campaignId);
  }

  Future<Map<String, dynamic>> getCampaignProgress(String campaignId) async {
    return await _campaignApi.getCampaignProgress(campaignId);
  }

  Future<List<Milestone>> getCampaignTimeline(String campaignId) async {
    final rawData = await _campaignApi.getCampaignTimeline(campaignId);
    return rawData.map((m) => Milestone.fromJson(m)).toList();
  }

  Future<Milestone> submitMilestoneEvidence({
    required String milestoneId,
    required String description,
    File? file,
  }) async {
    return await _milestoneApi.submitEvidence(
      milestoneId: milestoneId,
      description: description,
      file: file,
    );
  }

  Future<Milestone> startMilestoneVoting(String milestoneId) async {
    return await _milestoneApi.startVoting(milestoneId);
  }

  Future<Map<String, dynamic>> getMilestoneVotingStatus(String milestoneId) async {
    return await _milestoneApi.getVoteStatus(milestoneId);
  }
}
