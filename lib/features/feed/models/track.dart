import 'user.dart';
import '../../../../core/constants/api_constants.dart';

class Track {
  final String id;
  final String title;
  final String artistName;
  final String? artworkUrl;
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

  factory Track.fromJson(Map<String, dynamic> json) {
    String normalizeUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      if (url.startsWith('http')) return url;
      // Ensure we don't end up with double slashes if baseUrl has one
      final base = ApiConstants.baseUrl.endsWith('/')
          ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
          : ApiConstants.baseUrl;
      final path = url.startsWith('/') ? url : '/$url';
      return '$base$path';
    }

    return Track(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Track',
      artistName: json['artistName']?.toString() ??
          json['artist_name']?.toString() ??
          'Unknown Artist',
      artworkUrl: normalizeUrl(json['artworkUrl'] ?? json['artwork_url']),
      streamUrl: normalizeUrl(json['streamUrl'] ?? json['stream_url'] ?? json['audio_url']),
      duration: Duration(
        seconds: (json['durationSeconds'] ?? json['duration_seconds'] ?? json['duration'] ?? 0) is int
            ? (json['durationSeconds'] ?? json['duration_seconds'] ?? json['duration'] ?? 0) as int
            : (json['durationSeconds'] ?? json['duration_seconds'] ?? json['duration'] ?? 0).toInt(),
      ),
      playCount: (json['playCount'] ?? json['play_count'] ?? 0) as int,
      likeCount: (json['likeCount'] ?? json['like_count'] ?? 0) as int,
      commentCount: (json['commentCount'] ?? json['comment_count'] ?? 0) as int,
      repostCount: (json['repostCount'] ?? json['repost_count'] ?? 0) as int,
      genres: List<String>.from(json['genres'] ?? (json['genre'] != null ? [json['genre']] : [])),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      uploader: json['uploader'] != null ? User.fromJson(json['uploader']) : null,
      isLiked: (json['isLiked'] ?? json['is_liked'] ?? false) as bool,
      isReposted: (json['isReposted'] ?? json['is_reposted'] ?? false) as bool,
      status: json['status']?.toString(),
      waveform: json['waveform'] != null
          ? List<double>.from(json['waveform'].map((x) => (x as num).toDouble()))
          : null,
    );
  }
}

