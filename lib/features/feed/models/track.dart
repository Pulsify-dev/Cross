import 'user.dart';
import '../../../../core/constants/api_constants.dart';

class Track {
  final String id;
  final String title;
  String artistName;
  String? artistId;
  String? artworkUrl;
  final String streamUrl;
  final Duration duration;
  final int playCount;
  int likeCount;
  int commentCount;
  int repostCount;
  final List<String> genres;
  final DateTime createdAt;
  final User? uploader;
  bool isLiked;
  bool isReposted;
  final String? status;
  final List<double>? waveform;

  Track({
    required this.id,
    required this.title,
    required this.artistName,
    this.artistId,
    this.artworkUrl,
    required this.streamUrl,
    required this.duration,
    this.playCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.repostCount = 0,
    this.genres = const [],
    required this.createdAt,
    this.uploader,
    this.isLiked = false,
    this.isReposted = false,
    this.status,
    this.waveform,
  });

  factory Track.fromJson(Map<String, dynamic> rawJson) {
    // Handle nested structures if present
    final json = (rawJson['track'] is Map<String, dynamic>)
        ? rawJson['track'] as Map<String, dynamic>
        : (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;

    String normalizeUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      if (url.startsWith('http')) return url;

      // If it starts with // it's a protocol-relative URL
      if (url.startsWith('//')) return 'https:$url';

      final rootBase = ApiConstants.socketUrl.endsWith('/')
          ? ApiConstants.socketUrl.substring(
              0,
              ApiConstants.socketUrl.length - 1,
            )
          : ApiConstants.socketUrl;

      final path = url.startsWith('/') ? url : '/$url';
      return '$rootBase$path';
    }


    final artistName = () {
      if (json['artist_name'] != null) return json['artist_name'].toString();
      if (json['artistName'] != null) return json['artistName'].toString();

      final artist = json['artist_id'] ?? 
                    json['artist'] ?? 
                    json['uploader'] ?? 
                    json['user'] ?? 
                    json['author'] ?? 
                    json['owner'];
                    
      if (artist is Map<String, dynamic>) {
        return artist['display_name']?.toString() ??
            artist['displayName']?.toString() ??
            artist['username']?.toString() ??
            artist['name']?.toString() ??
            artist['displayname']?.toString() ??
            'Unknown Artist';
      }
      
      // If it's just an ID string or null, check if there's a name field at root
      final rootName = json['artist_name'] ?? 
                      json['artistName'] ?? 
                      json['username'] ?? 
                      json['displayName'] ?? 
                      json['display_name'] ??
                      json['uploader_name'] ??
                      json['user_name'] ??
                      json['author_name'] ??
                      json['owner_name'];

      if (rootName != null) return rootName.toString();

      return 'Unknown Artist';
    }();

    final artistId = () {
      final artist = json['artist_id'] ?? 
                    json['artist'] ?? 
                    json['uploader'] ?? 
                    json['user'] ??
                    json['author'] ??
                    json['owner'];
      if (artist is String) return artist;
      if (artist is Map<String, dynamic>) {
         return artist['id']?.toString() ?? 
                artist['_id']?.toString() ?? 
                artist['user_id']?.toString();
      }
      return json['user_id']?.toString() ?? json['userId']?.toString();
    }();

    return Track(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Track',
      artistName: artistName,
      artistId: artistId,
      artworkUrl: normalizeUrl(() {
        final artwork =
            json['artwork_url'] ??
            json['artworkUrl'] ??
            json['artwork'] ??
            json['cover_url'] ??
            json['cover'] ??
            json['imageUrl'] ??
            json['image_url'] ??
            json['artwork_path'];

        if (artwork is Map) {
          return artwork['url'] ?? artwork['path'] ?? artwork['link'];
        }
        
        if (artwork != null && artwork.toString().isNotEmpty) {
          return artwork.toString();
        }

        // Fallback to artist/uploader avatar
        final u = json['uploader'] ?? json['artist'] ?? json['user'];
        if (u is Map) {
          return u['profileImageUrl'] ?? u['avatar_url'] ?? u['avatar'];
        }
        
        return null;
      }()),
      streamUrl: normalizeUrl(
        json['streamUrl'] ??
            json['stream_url'] ??
            json['audio_url'] ??
            json['audio_path'] ??
            (json['audio'] is Map ? json['audio']['url'] : json['audio']),
      ),
      duration: Duration(
        seconds: (json['duration'] ??
                json['durationSeconds'] ??
                json['duration_seconds'] ??
                0) is int
            ? (json['duration'] ??
                json['durationSeconds'] ??
                json['duration_seconds'] ??
                0)
            : (json['duration'] ??
                    json['durationSeconds'] ??
                    json['duration_seconds'] ??
                    0)
                .toInt(),
      ),
      playCount: (json['play_count'] ?? json['playCount'] ?? 0) as int,
      likeCount: (json['like_count'] ?? json['likeCount'] ?? 0) as int,
      commentCount: (json['comment_count'] ?? json['commentCount'] ?? 0) as int,
      repostCount: (json['repost_count'] ?? json['repostCount'] ?? 0) as int,
      genres: List<String>.from(
        json['genres'] ?? (json['genre'] != null ? [json['genre']] : []),
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      uploader: () {
        final u = json['uploader'] ?? json['artist'] ?? json['user'];
        if (u is Map<String, dynamic>) {
          return User.fromJson(u);
        }
        return null;
      }(),
      isLiked: (json['isLiked'] ?? json['is_liked'] ?? false) as bool,
      isReposted: (json['isReposted'] ?? json['is_reposted'] ?? false) as bool,
      status: json['status']?.toString(),
      waveform: json['waveform'] != null
          ? List<double>.from(
              json['waveform'].map((x) => (x as num).toDouble()),
            )
          : null,
    );
  }
}
