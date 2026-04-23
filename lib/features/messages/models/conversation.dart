import '../../feed/models/user.dart';
import 'message.dart';

class Conversation {
  final String id;
  final User otherUser;
  final Message? lastMessage;
  final int unreadCount;
  final bool isBlocked;
  final DateTime? lastMessageTime;

  Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    this.isBlocked = false,
    this.lastMessageTime,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final otherParticipant = json['otherParticipant'] ?? json['other_participant'] ?? json['other_user'] ?? {};
    final lastMessageJson = json['lastMessage'] ?? json['last_message'] ?? json['last_message_data'];
    final lastMessageTimeString = json['lastMessageTime'] ?? json['last_message_time'] ?? json['last_message_at'];

    return Conversation(
      id: json['id'] ?? json['_id'] ?? '',
      otherUser: User.fromJson(Map<String, dynamic>.from(otherParticipant ?? {})),
      lastMessage: lastMessageJson != null
          ? Message.fromJson(Map<String, dynamic>.from(lastMessageJson))
          : null,
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
      isBlocked: json['isBlocked'] ?? json['is_blocked'] ?? false,
      lastMessageTime: lastMessageTimeString != null
          ? DateTime.tryParse(lastMessageTimeString.toString())
          : null,
    );
  }

  Conversation copyWith({
    String? id,
    User? otherUser,
    Message? lastMessage,
    int? unreadCount,
    bool? isBlocked,
    DateTime? lastMessageTime,
  }) {
    return Conversation(
      id: id ?? this.id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isBlocked: isBlocked ?? this.isBlocked,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
