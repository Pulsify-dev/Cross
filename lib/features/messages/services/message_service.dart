import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/api_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class MessageService {
  final ApiService _apiService;

  MessageService(this._apiService);

  Future<List<Conversation>> getConversations({int page = 1, int limit = 20}) async {
    final response = await _apiService.get(
      ApiEndpoints.conversations(page: page, limit: limit),
      authRequired: true,
    );

    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final items = data['conversations'];
        if (items is List) {
          return items
              .map((item) => Conversation.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      } else if (response['conversations'] is List) {
        return (response['conversations'] as List)
            .map((item) => Conversation.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    return [];
  }

  Future<Conversation?> startOrGetConversation(String recipientId) async {
    final response = await _apiService.post(
      ApiEndpoints.startConversation(),
      body: {'recipient_id': recipientId},
      authRequired: true,
    );

    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return Conversation.fromJson(Map<String, dynamic>.from(data));
      }
    }

    return null;
  }

  Future<int> getTotalUnreadCount() async {
    final response = await _apiService.get(
      ApiEndpoints.conversationsUnreadCount,
      authRequired: true,
    );

    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic> && data['unread_count'] != null) {
        return int.tryParse(data['unread_count'].toString()) ?? 0;
      }
    }

    return 0;
  }

  Future<List<Message>> getChatHistory(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiService.get(
      ApiEndpoints.conversationMessages(
        conversationId,
        page: page,
        limit: limit,
      ),
      authRequired: true,
    );

    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic> && data['messages'] is List) {
        return (data['messages'] as List)
            .map((item) => Message.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      if (response['messages'] is List) {
        return (response['messages'] as List)
            .map((item) => Message.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    return [];
  }

  Future<Message?> sendMessage(
    String conversationId,
    String text, {
    Map<String, dynamic>? sharedEntity,
  }) async {
    final requestBody = <String, dynamic>{'text': text};
    if (sharedEntity != null && sharedEntity.isNotEmpty) {
      requestBody['shared_entity'] = sharedEntity;
    }

    final response = await _apiService.post(
      ApiEndpoints.sendMessage(conversationId),
      body: requestBody,
      authRequired: true,
    );

    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        if (data['message'] is Map) {
          return Message.fromJson(
              Map<String, dynamic>.from(data['message'] as Map));
        }

        if (data['messages'] is List && data['messages'].isNotEmpty) {
          return Message.fromJson(
              Map<String, dynamic>.from(data['messages'].first as Map));
        }

        return Message.fromJson(Map<String, dynamic>.from(data));
      }
    }

    return null;
  }

  Future<bool> markConversationRead(String conversationId) async {
    await _apiService.put(
      ApiEndpoints.markConversationRead(conversationId),
      authRequired: true,
    );
    return true;
  }
}
