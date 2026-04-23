import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialSdkService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
    serverClientId: '48046590462-ggpsabgek56jagfi6o0sav2e9a87rdf8.apps.googleusercontent.com',
  );

  Future<String?> getGoogleProviderToken() async {
    _log('getGoogleProviderToken', 'Starting Google sign-in');
    final account = await _googleSignIn.signIn();
    if (account == null) {
      _log('getGoogleProviderToken', 'User cancelled Google sign-in');
      return null;
    }

    final auth = await account.authentication;
    final token = auth.idToken ?? auth.accessToken;
    if (token == null || token.isEmpty) {
      _log('getGoogleProviderToken', 'No token returned from Google SDK');
      throw Exception('Failed to get Google provider token.');
    }

    _log('getGoogleProviderToken', 'Google token retrieved (idToken: ${auth.idToken != null}, accessToken: ${auth.accessToken != null})');
    return token;
  }

  Future<String?> getFacebookProviderToken() async {
    _log('getFacebookProviderToken', 'Starting Facebook sign-in');
    final result = await FacebookAuth.instance.login(
      permissions: ['public_profile', 'email'],
    );

    switch (result.status) {
      case LoginStatus.success:
        final token = result.accessToken?.tokenString;
        if (token == null || token.isEmpty) {
          _log('getFacebookProviderToken', 'Facebook login succeeded but no token returned');
          throw Exception('Failed to get Facebook provider token.');
        }
        _log('getFacebookProviderToken', 'Facebook token retrieved');
        return token;
      case LoginStatus.cancelled:
        _log('getFacebookProviderToken', 'User cancelled Facebook sign-in');
        return null;
      case LoginStatus.failed:
        _log('getFacebookProviderToken', 'Facebook login failed: ${result.message}');
        throw Exception(result.message ?? 'Facebook login failed.');
      case LoginStatus.operationInProgress:
        _log('getFacebookProviderToken', 'Facebook login already in progress');
        throw Exception('Facebook login is already in progress.');
    }
  }

  void _log(String method, String message) {
    if (kDebugMode) {
      debugPrint('[SocialSdkService.$method] $message');
    }
  }
}
