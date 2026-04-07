import 'user.dart';

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
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      title: json['title'],
      artistName: json['artistName'],
      artworkUrl: json['artworkUrl'],
      streamUrl: json['streamUrl'],
      duration: Duration(seconds: json['durationSeconds'] ?? 0),
      playCount: json['playCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      repostCount: json['repostCount'] ?? 0,
      genres: List<String>.from(json['genres'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      uploader: json['uploader'] != null
          ? User.fromJson(json['uploader'])
          : null,
      isLiked: json['isLiked'] ?? false,
    );
  }
}
