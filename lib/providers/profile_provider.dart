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

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? email,
    String? location,
    bool? isPrivate,
    List<String>? favoriteGenres,
    Map<String, String>? socialLinks,
    Uint8List? avatarBytes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.updateProfile(
        displayName: displayName,
        bio: bio,
        email: email,
        location: location,
        isPrivate: isPrivate,
        favoriteGenres: favoriteGenres,
        socialLinks: socialLinks,
        avatarBytes: avatarBytes,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}