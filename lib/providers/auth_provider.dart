import 'package:flutter/material.dart';
import 'package:cross/core/services/session_service.dart';
import 'package:cross/features/auth/models/user_model.dart';
import 'package:cross/features/auth/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

  Future<void> checkLoginStatus() async {
    _isLoggedIn = await _sessionService.isLoggedIn();
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      _currentUser = response.user;
      _isLoggedIn = true;

      await _sessionService.saveAccessToken(response.accessToken);
      await _sessionService.saveRefreshToken(response.refreshToken);
      await _sessionService.setLoggedIn(true);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(
        username: username,
        email: email,
        password: password,
      );

      _currentUser = response.user;
      _isLoggedIn = true;

      await _sessionService.saveAccessToken(response.accessToken);
      await _sessionService.saveRefreshToken(response.refreshToken);
      await _sessionService.setLoggedIn(true);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordReset({
    required String email,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordReset(email: email);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send reset link';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.logout();
      await _sessionService.clearSession();

      _currentUser = null;
      _isLoggedIn = false;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Logout failed';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}