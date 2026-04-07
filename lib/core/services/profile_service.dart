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

  Future<ProfileData> getProfile() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.profile,
        authRequired: true,
      );

      return ProfileData.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProfileData> updateProfile({
    String? displayName,
    String? bio,
    String? email,
    String? location,
    bool? isPrivate,
    List<String>? favoriteGenres,
    Map<String, String>? socialLinks,
    Uint8List? avatarBytes,
  }) async {
    try {
      // If there's an avatar image to upload, upload it first
      if (avatarBytes != null) {
        await _uploadAvatar(avatarBytes);
      }

      // Update profile fields
      final Map<String, dynamic> body = {};

      if (displayName != null) body['display_name'] = displayName;
      if (bio != null) body['bio'] = bio;
      if (location != null) body['location'] = location;
      if (isPrivate != null) body['is_private'] = isPrivate;
      if (favoriteGenres != null) body['favorite_genres'] = favoriteGenres;
      if (socialLinks != null) body['social_links'] = socialLinks;

      // Only make the PATCH request if there are fields to update
      if (body.isEmpty) {
        // If only avatar was uploaded, fetch and return updated profile
        return await getProfile();
      }

      final response = await _apiService.patch(
        ApiEndpoints.updateProfile,
        body: body,
        authRequired: true,
      );

      return ProfileData.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _uploadAvatar(Uint8List avatarBytes) async {
    try {
      final files = <http.MultipartFile>[
        http.MultipartFile.fromBytes(
          'file',
          avatarBytes,
          filename: 'avatar.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ];

      await _apiService.postMultipart(
        ApiEndpoints.uploadAvatar,
        files: files,
        authRequired: true,
      );
    } catch (e) {
      rethrow;
    }
  }
}