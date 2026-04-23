class ApiConversation {
  final String id;
  final String otherUserId;
  final String otherUsername;
  final String otherDisplayName;
  final String? otherAvatarUrl;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final String? lastMessageText;
  final String? lastMessageSenderId;

  const ApiConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherDisplayName,
    this.otherAvatarUrl,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.lastMessageText,
    this.lastMessageSenderId,
  });

  factory ApiConversation.fromJson(Map<String, dynamic> json) {
    final other =
        (json['other_participant'] as Map?)?.cast<String, dynamic>() ?? {};
    final lastMsg =
        (json['last_message'] as Map?)?.cast<String, dynamic>() ?? {};
    return ApiConversation(
      id: json['_id']?.toString() ?? '',
      otherUserId: other['_id']?.toString() ?? '',
      otherUsername: other['username']?.toString() ?? '',
      otherDisplayName:
          other['display_name']?.toString() ??
          other['username']?.toString() ??
          'Unknown',
      otherAvatarUrl: other['avatar_url']?.toString(),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
      lastMessageText: lastMsg['text']?.toString(),
      lastMessageSenderId: lastMsg['sender_id']?.toString(),
    );
  }
}
