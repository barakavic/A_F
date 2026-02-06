import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import '../../core/config/api_config.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys for secure storage
  static const String _tokenKey = 'jwt_token';
  static const String _userRoleKey = 'user_role';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        data: {
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        final role = response.data['role'] ?? 'fundraiser'; // Default to fundraiser if not provided

        await _saveAuthData(token, role);
        return response.data;
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
    required Map<String, dynamic> profileData,
  }) async {
    final String endpoint = role == 'contributor' 
        ? ApiConfig.registerContributor 
        : ApiConfig.registerFundraiser;

    try {
      final response = await _apiService.post(
        endpoint,
        data: {
          'email': email,
          'password': password,
          ...profileData,
        },
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveAuthData(String token, String role) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userRoleKey, value: role);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userRoleKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
