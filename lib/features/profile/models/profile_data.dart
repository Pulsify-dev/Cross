import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProfileData {
  ProfileData({
    this.avatarPath,
    this.avatarBytes,
    required this.username,
    required this.bio,
    required this.email,
  });

  final String? avatarPath;
  final Uint8List? avatarBytes;
  final String username;
  final String bio;
  final String email;

  ProfileData copyWith({
    String? avatarPath,
    Uint8List? avatarBytes,
    String? username,
    String? bio,
    String? email,
  }) {
    return ProfileData(
      avatarPath: avatarPath ?? this.avatarPath,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      email: email ?? this.email,
    );
  }

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final profileJson = _extractProfileJson(json);

    return ProfileData(
      avatarPath: _extractString(
        profileJson,
        ['avatarPath', 'avatar_url', 'avatarUrl', 'profileImageUrl'],
      ),
      username: _extractString(profileJson, ['username', 'name']),
      bio: _extractString(profileJson, ['bio', 'description', 'about']),
      email: _extractString(profileJson, ['email']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatarPath': avatarPath,
      'username': username,
      'bio': bio,
      'email': email,
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