import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProfileData {
  ProfileData({
    this.id,
    this.avatarPath,
    this.avatarBytes,
    required this.username,
    required this.bio,
    required this.email,
    this.displayName,
    this.location,
    this.favoriteGenres,
    this.socialLinks,
    this.isPrivate,
  });

  final String? id;
  final String? avatarPath;
  final Uint8List? avatarBytes;
  final String username;
  final String bio;
  final String email;
  final String? displayName;
  final String? location;
  final List<String>? favoriteGenres;
  final Map<String, String>? socialLinks;
  final bool? isPrivate;

  ProfileData copyWith({
    String? id,
    String? avatarPath,
    Uint8List? avatarBytes,
    String? username,
    String? bio,
    String? email,
    String? displayName,
    String? location,
    List<String>? favoriteGenres,
    Map<String, String>? socialLinks,
    bool? isPrivate,
  }) {
    return ProfileData(
      id: id ?? this.id,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      location: location ?? this.location,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      socialLinks: socialLinks ?? this.socialLinks,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final profileJson = _extractProfileJson(json);

    return ProfileData(
      id: _extractString(profileJson, ['id', 'user_id', '_id']),
      avatarPath: _extractString(profileJson, [
        'avatarPath',
        'avatar_url',
        'avatarUrl',
        'profileImageUrl',
      ]),
      username: _extractString(profileJson, ['username', 'name']),
      bio: _extractString(profileJson, ['bio', 'description', 'about']),
      email: _extractString(profileJson, ['email']),
      displayName: _extractString(profileJson, ['display_name', 'displayName']),
      location: _extractString(profileJson, ['location']),
      favoriteGenres: _extractList(profileJson, [
        'favorite_genres',
        'favoriteGenres',
      ]),
      socialLinks: _extractMap(profileJson, ['social_links', 'socialLinks']),
      isPrivate: _extractBool(profileJson, ['is_private', 'isPrivate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatarPath': avatarPath,
      'username': username,
      'bio': bio,
      'email': email,
      'display_name': displayName,
      'location': location,
      'favorite_genres': favoriteGenres,
      'social_links': socialLinks,
      'is_private': isPrivate,
    };
  }

  static Map<String, dynamic> _extractProfileJson(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json,
      json['data'],
      json['user'],
      json['profile'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        return candidate;
      }
    }

    return json;
  }

  static String _extractString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        return value.toString();
      }
    }

    return '';
  }

  static List<String>? _extractList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
    }
    return null;
  }

  static Map<String, String>? _extractMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map) {
        return value.cast<String, String>();
      }
    }
    return null;
  }

  static bool? _extractBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
    }
    return null;
  }
}

ImageProvider<Object> avatarImage({String? path, Uint8List? bytes}) {
  if (bytes != null) {
    return MemoryImage(bytes);
  }

  if (path == null || path.isEmpty) {
    // No image available; the Image widget's errorBuilder will show a neutral background.
    return MemoryImage(Uint8List(0));
  }

  if (path.startsWith('http')) {
    return NetworkImage(path);
  }

  if (path.startsWith('file://')) {
    return FileImage(File.fromUri(Uri.parse(path)));
  }

  return FileImage(File(path));
}
