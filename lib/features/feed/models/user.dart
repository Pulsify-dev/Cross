import '../../../../core/constants/api_constants.dart';

class User {
  final String id;
  final String username;
  final String? email;
  final String displayName;
  final String? profileImageUrl;
  final int followersCount;
  final int followingCount;
  final int tracksCount;
  final String? bio;

  User({
    required this.id,
    required this.username,
    this.email,
    required this.displayName,
    this.profileImageUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.tracksCount = 0,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String? normalizeUrl(String? url) {
      if (url == null || url.isEmpty) return null;
      if (url.startsWith('http')) return url;
      if (url.startsWith('//')) return 'https:$url';
      final rootBase = ApiConstants.socketUrl.endsWith('/')
          ? ApiConstants.socketUrl.substring(0, ApiConstants.socketUrl.length - 1)
          : ApiConstants.socketUrl;
      final path = url.startsWith('/') ? url : '/$url';
      return '$rootBase$path';
    }

    return User(
      id: json['id'] ?? json['_id'] ?? json['user_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      displayName: json['displayName'] ?? json['display_name'] ?? json['username'] ?? 'Unknown',
      profileImageUrl: normalizeUrl(json['profileImageUrl'] ??
          json['profile_image_url'] ??
          json['avatar_url'] ??
          json['avatarUrl'] ??
          json['avatar'] ??
          json['image_url']),
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      tracksCount: json['tracksCount'] ?? 0,
      bio: json['bio'],
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? profileImageUrl,
    int? followersCount,
    int? followingCount,
    int? tracksCount,
    String? bio,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      tracksCount: tracksCount ?? this.tracksCount,
      bio: bio ?? this.bio,
    );
  }
}
