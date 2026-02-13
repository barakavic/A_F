import 'package:dio/dio.dart';
import '../lib/data/models/project.dart';

void main() async {
  print('🧪 Starting Manual API Connection Test...');
  
  // We use localhost because this script runs on the same machine as Docker
  final String testUrl = 'http://localhost:8000/api/v1/campaigns/';
  final dio = Dio();

  try {
    print('Fetching campaigns from: $testUrl');
    final response = await dio.get(testUrl);

    if (response.statusCode == 200) {
      print('Connection Successful! Received ${response.data.length} campaigns.');
      
      List<dynamic> rawData = response.data;
      List<Project> projects = rawData.map((json) => Project.fromJson(json)).toList();

      print('\n--- Campaign List ---');
      for (var project in projects) {
        print('   Title: ${project.title}');
        print('   Status: ${project.status}');
        print('   Goal: KES ${project.goalAmount}');
        print('   Raised: KES ${project.raisedAmount}');
        print('   ID: ${project.id}');
        print('----------------------');
      }
    } else {
      print(' Failed with status code: ${response.statusCode}');
    }
  } on DioException catch (e) {
    print(' API Error: ${e.message}');
    if (e.response != null) {
      print('   Response Data: ${e.response?.data}');
    }
  } catch (e) {
    print('Unexpected Error: $e');
  }
}
