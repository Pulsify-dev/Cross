import 'track.dart';
import 'user.dart';

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
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      artworkUrl: json['artwork_url'],
      creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
      trackCount: json['track_count'] ?? 0,
      tracks: json['tracks'] != null
          ? (json['tracks'] as List).map((i) => Track.fromJson(i)).toList()
          : [],
    );
  }
}
