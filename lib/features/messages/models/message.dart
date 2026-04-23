import '../../feed/models/user.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? trackLink; // For sharing tracks
  final String? playlistLink; // For sharing playlists

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.trackLink,
    this.playlistLink,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final timestampValue = json['timestamp'] ??
        json['createdAt'] ??
        json['created_at'] ??
        json['updatedAt'] ??
        json['updated_at'];

    final senderId = _resolveUserId(
      json,
      keys: const ['senderId', 'sender_id', 'sender', 'from', 'author'],
    );
    final receiverId = _resolveUserId(
      json,
      keys: const ['receiverId', 'receiver_id', 'receiver', 'to', 'recipient'],
    );

    return Message(
      id: json['id'] ?? json['_id'] ?? '',
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? '',
      senderId: senderId,
      receiverId: receiverId,
      content: json['content'] ?? json['text'] ?? '',
      timestamp: timestampValue != null
          ? DateTime.tryParse(timestampValue.toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      trackLink: json['trackLink'] ??
          json['shared_entity'] is Map
          ? json['shared_entity']['id']?.toString()
          : null,
      playlistLink: json['playlistLink'],
    );
  }

  static String _resolveUserId(
    Map<String, dynamic> json, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      if (!json.containsKey(key)) continue;
      final extracted = _extractId(json[key]);
      if (extracted.isNotEmpty) {
        return extracted;
      }
    }
    return '';
  }

  static String _extractId(dynamic value) {
    if (value == null) return '';

    if (value is String) {
      return value.trim();
    }

    if (value is num || value is bool) {
      return value.toString().trim();
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value as Map);
      const idKeys = [
        'id',
        '_id',
        'user_id',
        'sender_id',
        'receiver_id',
        'participant_id',
      ];

      for (final idKey in idKeys) {
        final nested = _extractId(map[idKey]);
        if (nested.isNotEmpty) {
          return nested;
        }
      }

      const objectKeys = ['user', 'participant', 'sender', 'receiver'];
      for (final objectKey in objectKeys) {
        final nested = _extractId(map[objectKey]);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return '';
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? trackLink,
    String? playlistLink,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      trackLink: trackLink ?? this.trackLink,
      playlistLink: playlistLink ?? this.playlistLink,
    );
  }
}
