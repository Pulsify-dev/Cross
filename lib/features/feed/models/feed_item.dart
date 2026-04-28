import 'track.dart';
import 'user.dart';
import 'album.dart';

enum FeedItemType { track, repost }

class FeedItem {
  final String type;
  final String entityType;
  final DateTime createdAt;
  final Track? track;
  final Album? album;
  final User artist;
  final User? repostedBy;

  FeedItem({
    required this.type,
    this.entityType = 'track',
    required this.createdAt,
    this.track,
    this.album,
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
    
    final entityType = json['entity_type'] ?? 'track';
    
    Map<String, dynamic>? trackData;
    Map<String, dynamic>? albumData;
    
    if (entityType == 'album' || json['album'] != null) {
      albumData = json['album'] as Map<String, dynamic>?;
    } else {
      trackData = json['track'] as Map<String, dynamic>?;
    }

    final artistData = json['artist'] as Map<String, dynamic>? ?? 
                      trackData?['artist_id'] as Map<String, dynamic>? ??
                      trackData?['artist'] as Map<String, dynamic>? ??
                      albumData?['artist_id'] as Map<String, dynamic>? ??
                      albumData?['artist'] as Map<String, dynamic>?;

    final track = trackData != null ? Track.fromJson(trackData) : null;
    final album = albumData != null ? Album.fromJson(albumData) : null;
    
    final artist = artistData != null
        ? User.fromJson(artistData)
        : User(id: '', username: 'unknown', displayName: 'Unknown');

    // Update track.artistName if it's unknown but we have artist info
    if (track != null && track.artistName == 'Unknown Artist' &&
        artist.displayName != 'Unknown') {
      track.artistName = artist.displayName;
    }

    // Ensure track has uploader/artistId for follow button support
    if (track != null && track.uploader == null && artist.id.isNotEmpty) {
      track.uploader = artist;
    }
    if (track != null && (track.artistId == null || track.artistId!.isEmpty) && artist.id.isNotEmpty) {
      track.artistId = artist.id;
    }
    
    if (album != null && (album.artistName == 'Unknown Artist' || album.artistName.isEmpty) &&
        artist.displayName != 'Unknown') {
      // Album doesn't have mutable artistName, but just in case we need it later
    }

    return FeedItem(
      type: json['type'] ?? 'track',
      entityType: entityType,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      track: track,
      album: album,
      artist: artist,
      repostedBy: json['reposted_by'] != null
          ? User.fromJson(json['reposted_by'])
          : null,
    );
  }
}
