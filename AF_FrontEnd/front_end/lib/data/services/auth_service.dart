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
  static const String _userNameKey = 'user_full_name';
  static const String _userIdKey = 'user_id';

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
        final role = response.data['role'] ?? 'fundraiser';
        final userId = response.data['account_id'];

        await _saveAuthData(token, role, userId);
        
        // Fetch full profile to get the name
        try {
          final profile = await getProfile();
          String? name;
          if (role == 'fundraiser') {
            name = profile['fundraiser_profile']?['company_name'];
          } else {
            name = profile['contributor_profile']?['uname'];
          }
          if (name != null) {
            await _storage.write(key: _userNameKey, value: name);
          }
        } catch (e) {
          print("Profile fetch error during login: $e");
        }

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
    String? publicKey,
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
          'public_key': publicKey,
          ...profileData,
        },
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveAuthData(String token, String role, [String? userId]) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userRoleKey, value: role);
    if (userId != null) {
      await _storage.write(key: _userIdKey, value: userId);
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  Future<String?> getUserDisplayName() async {
    return await _storage.read(key: _userNameKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get(ApiConfig.me);
      return response.data;
    } catch (e) {
      rethrow;
    }
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
