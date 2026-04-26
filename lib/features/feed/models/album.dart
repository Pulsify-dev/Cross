import 'track.dart';
import '../../../../core/constants/api_constants.dart';

class Album {
  final String id;
  final String title;
  final String artistId;
  final String artistName;
  final String artistUsername;
  final String? artworkUrl;
  final int trackCount;
  final String? genre;
  final DateTime? createdAt;
  final List<Track> tracks;

  Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    required this.artistUsername,
    this.artworkUrl,
    this.trackCount = 0,
    this.genre,
    this.createdAt,
    this.tracks = const [],
  });

  factory Album.fromJson(Map<String, dynamic> json) {
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

    String artistIdStr = '';
    String artistNameStr = '';
    String artistUsernameStr = '';
    
    if (json['artist_id'] is Map<String, dynamic>) {
      final artistMap = json['artist_id'] as Map<String, dynamic>;
      artistIdStr = artistMap['_id'] ?? artistMap['id'] ?? '';
      artistNameStr = artistMap['display_name'] ?? artistMap['displayName'] ?? artistMap['name'] ?? artistMap['username'] ?? '';
      artistUsernameStr = artistMap['username'] ?? '';
    } else {
      artistIdStr = json['artist_id']?.toString() ?? '';
      artistNameStr = json['artist_name'] ?? '';
      artistUsernameStr = json['artist_username'] ?? '';
    }

    return Album(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      artistId: artistIdStr,
      artistName: artistNameStr,
      artistUsername: artistUsernameStr,
      artworkUrl: normalizeUrl(json['cover_url'] ?? json['artwork_url']),
      trackCount: json['track_count'] ?? 0,
      genre: json['genre'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      tracks: json['tracks'] != null
          ? (json['tracks'] as List).map((i) => Track.fromJson(i)).toList()
          : [],
    );
  }
}
