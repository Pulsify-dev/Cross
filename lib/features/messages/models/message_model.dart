class ApiMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final bool isRead;
  final DateTime createdAt;

  const ApiMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.isRead = false,
    required this.createdAt,
  });

  factory ApiMessage.fromJson(Map<String, dynamic> json) {
    return ApiMessage(
      id: json['_id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
