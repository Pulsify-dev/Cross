import 'package:cross/features/auth/models/auth_response_model.dart';
import 'package:cross/features/auth/models/user_model.dart';

class AuthService {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return AuthResponseModel(
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      user: UserModel(
        id: '1',
        username: 'mohammad',
        email: email,
        isVerified: true,
      ),
    );
  }

  Future<AuthResponseModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return AuthResponseModel(
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      user: UserModel(
        id: '2',
        username: username,
        email: email,
        isVerified: false,
      ),
    );
  }

  Future<void> sendPasswordReset({
    required String email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<AuthResponseModel> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const AuthResponseModel(
      accessToken: 'google_mock_access_token',
      refreshToken: 'google_mock_refresh_token',
      user: UserModel(
        id: '3',
        username: 'google_user',
        email: 'googleuser@example.com',
        isVerified: true,
      ),
    );
  }

  Future<AuthResponseModel> loginWithApple() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const AuthResponseModel(
      accessToken: 'apple_mock_access_token',
      refreshToken: 'apple_mock_refresh_token',
      user: UserModel(
        id: '4',
        username: 'apple_user',
        email: 'appleuser@example.com',
        isVerified: true,
      ),
    );
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}