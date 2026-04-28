import 'package:cross/core/constants/api_endpoints.dart';
import 'package:cross/core/services/api_service.dart';
import 'package:cross/features/auth/models/auth_response_model.dart';

class AuthService {
  AuthService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.login,{},
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid login response.');
    }

    return AuthResponseModel.fromJson(response);
  }

  Future<AuthResponseModel> register({
    required String username,
    required String email,
    required String password,
    required String captchaToken,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.register,{},
      body: {
        'username': username,
        'email': email,
        'password': password,
        'captcha_token': captchaToken,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid registration response.');
    }

    return AuthResponseModel.fromJson(response);
  }

  Future<AuthResponseModel> socialLogin({
    required String provider,
    required String token,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.socialLogin(provider),{},
      body: {'token': token},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid social login response.');
    }

    return AuthResponseModel.fromJson(response);
  }

  Future<String> verifyEmail({
    required String token,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.verifyEmail,{},
      body: {'token': token},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid verify email response.');
    }

    return response['message']?.toString() ?? 'Email verification completed.';
  }

  Future<AuthResponseModel> refreshToken({
    required String refreshToken,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.refreshToken,{},
      body: {'refresh_token': refreshToken},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid refresh token response.');
    }

    return AuthResponseModel.fromJson(response);
  }

  Future<String> sendPasswordReset({
    required String email,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.forgotPassword,{},
      body: {'email': email},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid forgot password response.');
    }

    return response['message']?.toString() ??
        'If that email address is in our database, we will send you a link to reset your password.';
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.resetPassword,{},
      body: {
        'token': token,
        'new_password': newPassword,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid reset password response.');
    }

    return response['message']?.toString() ??
        'Password has been successfully reset. You can now log in.';
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _apiService.get(
      ApiEndpoints.myProfile,
      authRequired: true,
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid profile response.');
    }

    return response;
  }

  Future<String> resendVerification({
    required String email,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.resendVerification,{},
      body: {'email': email},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException('Invalid resend verification response.');
    }

    return response['message']?.toString() ??
        'If that email is registered, a new verification link has been sent.';
  }

  Future<void> logout({
    required String refreshToken,
  }) async {
    await _apiService.post(
      ApiEndpoints.logout,{},
      body: {'refresh_token': refreshToken},
      authRequired: true,
    );
  }
}