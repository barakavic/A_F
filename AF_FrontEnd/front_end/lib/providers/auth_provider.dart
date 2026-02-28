import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _userRole;
  String? _userDisplayName;
  String? _userId;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get userRole => _userRole;
  String? get userDisplayName => _userDisplayName;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;

  // Check if user is already logged in on app start
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _isAuthenticated = true;
        _userRole = await _authService.getUserRole();
        _userDisplayName = await _authService.getUserDisplayName();
        _userId = await _authService.getUserId();
      } else {
        _isAuthenticated = false;
        _userRole = null;
        _userDisplayName = null;
        _userId = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _userRole = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _authService.login(email, password);
      _isAuthenticated = true;
      _userRole = data['role'];
      _userDisplayName = await _authService.getUserDisplayName();
      _userId = await _authService.getUserId();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String role,
    String? publicKey,
    required Map<String, dynamic> profileData,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.register(
        email: email,
        password: password,
        role: role,
        publicKey: publicKey,
        profileData: profileData,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _userRole = null;
    _userDisplayName = null;
    _userId = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
