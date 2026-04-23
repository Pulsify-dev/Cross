import '../../../core/services/api_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'messaging_service.dart';

class ApiMessagingService implements MessagingService {
  final ApiService _api;

  ApiMessagingService(this._api);

  @override
  Future<List<ApiConversation>> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      '/conversations?page=$page&limit=$limit',
      authRequired: true,
    );
    final data = (response['data'] ?? response) as Map<String, dynamic>;
    final list = (data['conversations'] as List?) ?? [];
    return list
        .map((j) => ApiConversation.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> startOrGetConversation(String recipientId) async {
    final response = await _api.post(
      '/conversations',
      body: {'recipient_id': recipientId},
      authRequired: true,
    );
    final data = (response['data'] ?? response) as Map<String, dynamic>;
    return data['_id']?.toString() ?? '';
  }

  @override
  Future<List<ApiMessage>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get(
      '/conversations/$conversationId/messages?page=$page&limit=$limit',
      authRequired: true,
    );
    final data = (response['data'] ?? response) as Map<String, dynamic>;
    final list = (data['messages'] as List?) ?? [];
    return list
        .map((j) => ApiMessage.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> sendMessageRest(String conversationId, String text) async {
    await _api.post(
      '/conversations/$conversationId/messages',
      body: {'text': text},
      authRequired: true,
    );
  }

  @override
  Future<void> markReadRest(String conversationId) async {
    await _api.put(
      '/conversations/$conversationId/read',
      authRequired: true,
    );
  }
}
