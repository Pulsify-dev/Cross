import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:cross/core/constants/api_endpoints.dart';
import 'package:cross/core/services/api_service.dart';
import 'package:cross/features/profile/models/profile_data.dart';

class ProfileService {
  ProfileService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<ProfileData> getProfile({required String userId}) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.profile(userId),
        authRequired: true,
      );

      return ProfileData.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProfileData> updateProfile({
    required String userId,
    String? username,
    String? bio,
    String? avatarPath,
    Uint8List? avatarBytes,
  }) async {
    try {
      final Map<String, dynamic> body = {};

      if (username != null) body['username'] = username;
      if (bio != null) body['bio'] = bio;
      if (avatarPath != null) body['avatarPath'] = avatarPath;

      final response = await _apiService.patch(
        ApiEndpoints.editProfile(userId),
        body: body,
        authRequired: true,
      );

      return ProfileData.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfileWithImage({
    required String userId,
    String? username,
    String? bio,
    Uint8List? avatarBytes,
  }) async {
    try {
      final fields = <String, String>{};
      final files = <http.MultipartFile>[];

      if (username != null) fields['username'] = username;
      if (bio != null) fields['bio'] = bio;

      if (avatarBytes != null) {
        files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            avatarBytes,
            filename: 'avatar.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      await _apiService.postMultipart(
        ApiEndpoints.editProfile(userId),
        fields: fields.isNotEmpty ? fields : null,
        files: files.isNotEmpty ? files : null,
        authRequired: true,
      );
    } catch (e) {
      rethrow;
    }
  }
}