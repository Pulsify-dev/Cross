class Comment {
  final String id;
  final String trackId;
  final String userId;
  final String username;
  final String? userProfileImageUrl;
  final String text;
  final Duration timestampInTrack;
  final DateTime createdAt;

  final int likeCount;
  final bool isLiked;
  final String? parentCommentId;

  Comment({
    required this.id,
    required this.trackId,
    required this.userId,
    required this.username,
    this.userProfileImageUrl,
    required this.text,
    required this.timestampInTrack,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
    this.parentCommentId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      trackId: json['trackId'],
      userId: json['userId'],
      username: json['username'],
      userProfileImageUrl: json['userProfileImageUrl'],
      text: json['text'],
      timestampInTrack: Duration(seconds: json['timestampSeconds'] ?? 0),
      createdAt: DateTime.parse(json['createdAt']),
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      parentCommentId: json['parentCommentId'],
    );
  }
}
