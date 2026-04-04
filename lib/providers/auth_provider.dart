import 'package:flutter/material.dart';
import 'package:cross/core/services/api_service.dart';
import 'package:cross/core/services/session_service.dart';
import 'package:cross/features/auth/models/auth_response_model.dart';
import 'package:cross/features/auth/models/user_model.dart';
import 'package:cross/features/auth/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  String? _successMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> checkLoginStatus() async {
    await restoreSession();
  }

  Future<void> restoreSession() async {
    _setLoading(true);

    try {
      final hasRefreshToken = await _sessionService.hasRefreshToken();
      if (!hasRefreshToken) {
        await _sessionService.clearSession();
        _currentUser = null;
        _isLoggedIn = false;
        notifyListeners();
        return;
      }

      await refreshSession();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const ApiException('Login response is missing user data.');
      }

      _currentUser = response.user;
      await _persistTokens(response);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e, fallback: 'Login failed.');
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
    _clearMessages();

    try {
      final response = await _authService.register(
        username: username,
        email: email,
        password: password,
      );

      _currentUser = response.user;
      _successMessage = response.message ??
          'Registration successful. Please check your email to verify.';

      await _persistTokens(response);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e, fallback: 'Registration failed.');
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
    _clearMessages();

    try {
      _successMessage = await _authService.sendPasswordReset(email: email);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          _getErrorMessage(e, fallback: 'Failed to send reset link.');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEmail({
    required String token,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      _successMessage = await _authService.verifyEmail(token: token);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          _getErrorMessage(e, fallback: 'Email verification failed.');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      _successMessage = await _authService.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          _getErrorMessage(e, fallback: 'Password reset failed.');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> refreshSession() async {
    _setLoading(true);
    _clearMessages();

    try {
      final savedRefreshToken = await _sessionService.getRefreshToken();
      if (savedRefreshToken == null || savedRefreshToken.isEmpty) {
        throw const ApiException('Session expired. Please log in again.');
      }

      final refreshed =
          await _authService.refreshToken(refreshToken: savedRefreshToken);
      await _persistTokens(refreshed);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          _getErrorMessage(e, fallback: 'Session refresh failed.');
      await _sessionService.clearSession();
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearMessages();

    String? backendError;

    try {
      final refreshToken = await _sessionService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _authService.logout(refreshToken: refreshToken);
      }
    } catch (e) {
      backendError = _getErrorMessage(e, fallback: 'Logout failed.');
    }

    try {
      await _sessionService.clearSession();

      _currentUser = null;
      _isLoggedIn = false;

      if (backendError != null && backendError.isNotEmpty) {
        _errorMessage = backendError;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = _getErrorMessage(
        e,
        fallback: 'Failed to clear local session.',
      );
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearMessages() {
    _clearMessages();
    notifyListeners();
  }

  Future<void> _persistTokens(AuthResponseModel response) async {
    final accessToken = response.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('Auth response is missing access token.');
    }

    final refreshToken = response.refreshToken;
    final existingRefreshToken = await _sessionService.getRefreshToken();
    final effectiveRefreshToken =
        (refreshToken != null && refreshToken.isNotEmpty)
            ? refreshToken
            : existingRefreshToken;

    await _sessionService.saveAccessToken(accessToken);

    if (effectiveRefreshToken != null && effectiveRefreshToken.isNotEmpty) {
      await _sessionService.saveRefreshToken(effectiveRefreshToken);
    }

    final hasValidSession =
      accessToken.isNotEmpty &&
        effectiveRefreshToken != null && effectiveRefreshToken.isNotEmpty;
    _isLoggedIn = hasValidSession;
    await _sessionService.setLoggedIn(hasValidSession);
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  String _getErrorMessage(Object error, {required String fallback}) {
    if (error is ApiException) {
      return error.message;
    }
    return fallback;
  }
}