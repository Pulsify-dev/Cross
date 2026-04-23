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
  final int repliesCount;

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
    this.repliesCount = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: (json['comment_id'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      trackId: (json['track_id'] ?? json['trackId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      username: json['username']?.toString() ?? 'Unknown',
      userProfileImageUrl: json['avatar_url'] ?? json['userProfileImageUrl'],
      text: json['text']?.toString() ?? '',
      timestampInTrack: Duration(
        seconds: (json['timestamp_seconds'] ?? json['timestampSeconds'] ?? 0) is int
            ? (json['timestamp_seconds'] ?? json['timestampSeconds'] ?? 0)
            : (json['timestamp_seconds'] ?? json['timestampSeconds'] ?? 0).toInt(),
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      likeCount: json['likes_count'] ?? json['likeCount'] ?? 0,
      isLiked: json['is_liked'] ?? json['isLiked'] ?? false,
      parentCommentId: json['parent_comment_id'] ?? json['parentCommentId'],
      repliesCount: json['replies_count'] ?? json['repliesCount'] ?? 0,
    );
  }
}
