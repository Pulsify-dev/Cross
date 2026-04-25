import 'track.dart';

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
    return Album(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artistId: json['artist_id'] ?? '',
      artistName: json['artist_name'] ?? '',
      artistUsername: json['artist_username'] ?? '',
      artworkUrl: json['artwork_url'],
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
