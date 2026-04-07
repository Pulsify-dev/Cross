import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialSdkService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  Future<String?> getGoogleProviderToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }

    final auth = await account.authentication;
    final token = auth.idToken ?? auth.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Failed to get Google provider token.');
    }

    return token;
  }

  Future<String?> getAppleProviderToken() async {
    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw Exception('Apple Sign-In is not available on this device.');
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const <AppleIDAuthorizationScopes>[
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final token = credential.identityToken;
    if (token == null || token.isEmpty) {
      throw Exception('Failed to get Apple provider token.');
    }

    return token;
  }

  Future<String?> getFacebookProviderToken() async {
    final result = await FacebookAuth.instance.login();

    switch (result.status) {
      case LoginStatus.success:
        final token = result.accessToken?.tokenString;
        if (token == null || token.isEmpty) {
          throw Exception('Failed to get Facebook provider token.');
        }
        return token;
      case LoginStatus.cancelled:
        return null;
      case LoginStatus.failed:
        throw Exception(result.message ?? 'Facebook login failed.');
      case LoginStatus.operationInProgress:
        throw Exception('Facebook login is already in progress.');
    }
  }
}
