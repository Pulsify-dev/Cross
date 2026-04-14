import 'package:flutter/foundation.dart';
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
  bool _isSocialLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  String? _successMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSocialLoading => _isSocialLoading;
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
        _log('restoreSession', 'No refresh token found, clearing session');
        await _sessionService.clearSession();
        _currentUser = null;
        _isLoggedIn = false;
        notifyListeners();
        return;
      }

      _log('restoreSession', 'Refresh token found, attempting silent refresh');
      final refreshed = await refreshSession();

      if (refreshed && _currentUser == null) {
        _log('restoreSession', 'Tokens refreshed but no user data, fetching profile');
        await _fetchAndSetProfile();
      }

      if (_isLoggedIn) {
        _log('restoreSession', 'Session restored successfully');
      }
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
      _log('login', 'Attempting login');
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const ApiException('Login response is missing user data.');
      }

      _currentUser = response.user;
      await _persistTokens(response);
      _log('login', 'Login successful, tokens stored');

      notifyListeners();
      return true;
    } catch (e) {
      _log('login', 'Login failed: ${_getErrorMessage(e, fallback: 'unknown')}');
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
    required String captchaToken,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      _log('register', 'Attempting registration with captcha token present: ${captchaToken.isNotEmpty}');
      final response = await _authService.register(
        username: username,
        email: email,
        password: password,
        captchaToken: captchaToken,
      );

      _currentUser = response.user;
      _successMessage = response.message ??
          'Registration successful. Please check your email to verify.';

      // Register response may not include tokens; keep existing session untouched.
      if (response.accessToken != null && response.accessToken!.isNotEmpty) {
        await _persistTokens(response);
        _log('register', 'Registration returned tokens, stored');
      } else {
        _log('register', 'Registration successful, no tokens (email verification pending)');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _log('register', 'Registration failed: ${_getErrorMessage(e, fallback: 'unknown')}');
      _errorMessage = _getErrorMessage(e, fallback: 'Registration failed.');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> socialLogin({
    required String provider,
    required String token,
  }) async {
    _isSocialLoading = true;
    _clearMessages();
    notifyListeners();

    try {
      _log('socialLogin', 'Attempting $provider login, token present: ${token.isNotEmpty}');
      final response = await _authService.socialLogin(
        provider: provider,
        token: token,
      );

      if (response.user == null) {
        throw const ApiException('Social login response is missing user data.');
      }

      _currentUser = response.user;
      await _persistTokens(response);
      _log('socialLogin', '$provider login successful, tokens stored');

      notifyListeners();
      return true;
    } catch (e) {
      _log('socialLogin', '$provider login failed: ${_getErrorMessage(e, fallback: 'unknown')}');
      _errorMessage = _getErrorMessage(e, fallback: 'Social login failed.');
      notifyListeners();
      return false;
    } finally {
      _isSocialLoading = false;
      notifyListeners();
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

  Future<bool> resendVerification({
    required String email,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      _successMessage = await _authService.resendVerification(email: email);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          _getErrorMessage(e, fallback: 'Failed to resend verification email.');
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
    _clearMessages();

    try {
      final savedRefreshToken = await _sessionService.getRefreshToken();
      if (savedRefreshToken == null || savedRefreshToken.isEmpty) {
        throw const ApiException('Session expired. Please log in again.');
      }

      _log('refreshSession', 'Attempting token refresh');
      final refreshed =
          await _authService.refreshToken(refreshToken: savedRefreshToken);
      await _persistTokens(refreshed);
      _log('refreshSession', 'Token refresh successful');

      // If refresh response includes user data, use it
      if (refreshed.user != null) {
        _currentUser = refreshed.user;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _log('refreshSession', 'Token refresh failed: ${_getErrorMessage(e, fallback: 'unknown')}');
      _errorMessage =
          _getErrorMessage(e, fallback: 'Session refresh failed.');
      await _sessionService.clearSession();
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchAndSetProfile() async {
    try {
      _log('_fetchAndSetProfile', 'Fetching user profile from /users/me');
      final profileJson = await _authService.getMyProfile();
      _currentUser = UserModel.fromJson(profileJson);
      _log('_fetchAndSetProfile', 'Profile loaded for user: ${_currentUser?.username ?? 'unknown'}');
      notifyListeners();
    } catch (e) {
      _log('_fetchAndSetProfile', 'Failed to fetch profile: ${_getErrorMessage(e, fallback: 'unknown')}');
      // Profile fetch failed but tokens are valid — don't kill the session.
      // User can still use the app; profile will load on next navigation.
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearMessages();

    String? backendError;

    try {
      final refreshToken = await _sessionService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        _log('logout', 'Calling backend logout');
        await _authService.logout(refreshToken: refreshToken);
        _log('logout', 'Backend logout successful');
      }
    } catch (e) {
      _log('logout', 'Backend logout failed: ${_getErrorMessage(e, fallback: 'unknown')}');
      backendError = _getErrorMessage(e, fallback: 'Logout failed.');
    }

    try {
      await _sessionService.clearSession();

      _currentUser = null;
      _isLoggedIn = false;

      if (backendError != null && backendError.isNotEmpty) {
        _errorMessage = backendError;
      }

      _log('logout', 'Local session cleared');
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

  void _log(String method, String message) {
    if (kDebugMode) {
      debugPrint('[AuthProvider.$method] $message');
    }
  }
}
