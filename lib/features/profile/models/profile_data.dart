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