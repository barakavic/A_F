import 'package:dio/dio.dart';
import 'dart:io';
import '../models/milestone.dart';
import 'api_client.dart';
import '../../core/config/api_config.dart';

class MilestoneApi {
  final ApiClient _apiClient = ApiClient();

  
  Future<Milestone> submitEvidence({
    required String milestoneId,
    required String description,
    File? file,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'description': description,
      });

      if (file != null) {
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ));
      }

      final response = await _apiClient.dio.post(
        '/milestones/$milestoneId/submit-evidence',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      
      return Milestone.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Fundraiser starts the voting period for a milestone.
  Future<Milestone> startVoting(String milestoneId) async {
    try {
      final response = await _apiClient.post('/milestones/$milestoneId/start-voting');
      return Milestone.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  
  Future<Map<String, dynamic>> getVoteStatus(String milestoneId) async {
    try {
      final response = await _apiClient.get('/milestones/$milestoneId/vote-status');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  
  Future<List<dynamic>> getMilestoneEvidence(String milestoneId) async {
    try {
      final response = await _apiClient.get('/milestones/$milestoneId/evidence');
      return response.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
