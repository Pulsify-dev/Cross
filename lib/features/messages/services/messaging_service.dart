import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class MessagingService {
  Future<List<ApiConversation>> getConversations({int page = 1, int limit = 20});
  Future<String> startOrGetConversation(String recipientId);
  Future<List<ApiMessage>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  });
  Future<void> sendMessageRest(String conversationId, String text);
  Future<void> markReadRest(String conversationId);
}
