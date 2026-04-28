import 'track.dart';
import 'user.dart';
import '../../../../core/constants/api_constants.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? artworkUrl;
  final User? creator;
  final int trackCount;
  final List<Track> tracks;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.artworkUrl,
    this.creator,
    this.trackCount = 0,
    this.tracks = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    String? normalizeUrl(String? url) {
      if (url == null || url.isEmpty) return null;
      if (url.endsWith('Default.png') || url.endsWith('default.png')) return null;
      if (url.startsWith('http')) return url;
      if (url.startsWith('//')) return 'https:$url';
      final rootBase = ApiConstants.socketUrl.endsWith('/')
          ? ApiConstants.socketUrl.substring(0, ApiConstants.socketUrl.length - 1)
          : ApiConstants.socketUrl;
      final path = url.startsWith('/') ? url : '/$url';
      return '$rootBase$path';
    }
    User? parsedCreator;
    final creatorData = json['creator_id'] ?? json['creator'] ?? json['owner'] ?? json['user'];
    
    if (creatorData is Map<String, dynamic>) {
      parsedCreator = User.fromJson(creatorData);
    } else if (json['creator_name'] != null) {
      parsedCreator = User(
        id: creatorData is String ? creatorData : '',
        username: json['creator_name'],
        displayName: json['creator_name'],
        profileImageUrl: normalizeUrl(json['creator_avatar_url'] ?? json['creator_avatar'] ?? json['avatar_url']),
      );
    }

    return Playlist(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['title'] ?? json['name'] ?? '',
      description: json['description'],
      artworkUrl: normalizeUrl(json['cover_url'] ?? json['artwork_url']),
      creator: parsedCreator,
      trackCount: json['track_count'] ?? 0,
      tracks: json['tracks'] != null
          ? (json['tracks'] as List).map((i) => Track.fromJson(i)).toList()
          : [],
    );
  }
}
