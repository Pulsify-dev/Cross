import 'track.dart';
import 'user.dart';

enum FeedItemType { track, repost }

class FeedItem {
  final String type;
  final DateTime createdAt;
  final Track track;
  final User artist;
  final User? repostedBy;

  FeedItem({
    required this.type,
    required this.createdAt,
    required this.track,
    required this.artist,
    this.repostedBy,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    // The API structure for a feed item:
    // {
    //   "type": "track" | "repost",
    //   "created_at": "...",
    //   "track": { ... },
    //   "artist": { ... },
    //   "reposted_by": { ... } (optional)
    // }
    
    // Sometimes 'track' contains 'artist_id' object, sometimes 'artist' is a sibling.
    // Let's handle both.
    
    final trackData = json['track'] as Map<String, dynamic>;
    final artistData = json['artist'] as Map<String, dynamic>? ?? 
                      trackData['artist_id'] as Map<String, dynamic>? ??
                      trackData['artist'] as Map<String, dynamic>?;

    final track = Track.fromJson(trackData);
    final artist = artistData != null ? User.fromJson(artistData) : User(id: '', username: 'unknown', displayName: 'Unknown');

    return FeedItem(
      type: json['type'] ?? 'track',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      track: track,
      artist: artist,
      repostedBy: json['reposted_by'] != null ? User.fromJson(json['reposted_by']) : null,
    );
  }
}
