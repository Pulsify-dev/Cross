import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProfileData {
  ProfileData({
    this.avatarPath,
    this.avatarBytes,
    required this.displayName,
    required this.bio,
    required this.email,
    this.location,
    this.iPrivate = false,
    this.favoriteGenres = const [],
    this.socialLinks = const {},
  });

  final String? avatarPath;
  final Uint8List? avatarBytes;
  final String displayName;
  final String bio;
  final String email;
  final String? location;
  final bool iPrivate;
  final List<String> favoriteGenres;
  final Map<String, String> socialLinks;

  ProfileData copyWith({
    String? avatarPath,
    Uint8List? avatarBytes,
    String? displayName,
    String? bio,
    String? email,
    String? location,
    bool? iPrivate,
    List<String>? favoriteGenres,
    Map<String, String>? socialLinks,
  }) {
    return ProfileData(
      avatarPath: avatarPath ?? this.avatarPath,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      location: location ?? this.location,
      iPrivate: iPrivate ?? this.iPrivate,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final profileJson = _extractProfileJson(json);

    return ProfileData(
      avatarPath: _extractString(
        profileJson,
        ['avatar_url', 'avatarPath', 'avatarUrl', 'profileImageUrl'],
      ),
      displayName: _extractString(
        profileJson,
        ['display_name', 'displayName', 'username', 'name'],
      ),
      bio: _extractString(profileJson, ['bio', 'description', 'about']),
      email: _extractString(profileJson, ['email']),
      location: _extractStringOrNull(profileJson, ['location']),
      iPrivate: _extractBool(profileJson, 'is_private', false),
      favoriteGenres: _extractList(profileJson, 'favorite_genres'),
      socialLinks: _extractMap(profileJson, 'social_links'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatarPath': avatarPath,
      'display_name': displayName,
      'bio': bio,
      'email': email,
      'location': location,
      'is_private': iPrivate,
      'favorite_genres': favoriteGenres,
      'social_links': socialLinks,
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

  static String _extractString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        return value.toString();
      }
    }

    return '';
  }

  static String? _extractStringOrNull(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        return value.toString();
      }
    }

    return null;
  }

  static bool _extractBool(
    Map<String, dynamic> json,
    String key,
    bool defaultValue,
  ) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    return defaultValue;
  }

  static List<String> _extractList(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static Map<String, String> _extractMap(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is Map) {
      return value.cast<String, String>();
    }
    return {};
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