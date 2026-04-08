import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cross/core/services/profile_service.dart';
import 'package:cross/features/profile/models/profile_data.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({ProfileService? profileService})
      : _profileService = profileService ?? ProfileService();

  final ProfileService _profileService;

  ProfileData? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileData? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile({required String userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile(userId: userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.getMyProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMyProfile({
    String? displayName,
    String? bio,
    String? location,
    List<String>? favoriteGenres,
    Map<String, String>? socialLinks,
    bool? isPrivate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.updateMyProfile(
        displayName: displayName,
        bio: bio,
        location: location,
        favoriteGenres: favoriteGenres,
        socialLinks: socialLinks,
        isPrivate: isPrivate,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadAvatar(Uint8List avatarBytes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.uploadAvatar(avatarBytes);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String userId,
    required ProfileData newProfile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.updateProfile(
        userId: userId,
        username: newProfile.username,
        bio: newProfile.bio,
        avatarPath: newProfile.avatarPath,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}