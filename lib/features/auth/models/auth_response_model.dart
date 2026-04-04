import 'package:cross/features/auth/models/user_model.dart';

class AuthResponseModel {
  final String? accessToken;
  final String? refreshToken;
  final UserModel? user;
  final String? message;

  const AuthResponseModel({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.message,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return AuthResponseModel(
      accessToken:
          json['access_token']?.toString() ?? json['accessToken']?.toString(),
      refreshToken: json['refresh_token']?.toString() ??
          json['refreshToken']?.toString(),
      user: userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : null,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user?.toJson(),
      'message': message,
    };
  }
}