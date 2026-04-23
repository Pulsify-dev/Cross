import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/session_service.dart';

class SocketService {
  io.Socket? _socket;
  final SessionService _sessionService;

  final _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _readController =
      StreamController<Map<String, dynamic>>.broadcast();

  SocketService({SessionService? sessionService})
      : _sessionService = sessionService ?? SessionService();

  Stream<Map<String, dynamic>> get onMessageNew => _messageController.stream;
  Stream<Map<String, dynamic>> get onConversationRead => _readController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected ?? false) return;

    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) return;

    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('message:new', (data) {
      if (data is Map && !_messageController.isClosed) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('conversation:read', (data) {
      if (data is Map && !_readController.isClosed) {
        _readController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  void joinConversation(String conversationId) {
    _socket?.emitWithAck(
      'conversation:join',
      {'conversation_id': conversationId},
      ack: (_) {},
    );
  }

  void sendMessage(String conversationId, String text) {
    _socket?.emit('message:new', {
      'conversation_id': conversationId,
      'text': text,
    });
  }

  void markRead(String conversationId) {
    _socket?.emitWithAck(
      'conversation:read',
      {'conversation_id': conversationId},
      ack: (_) {},
    );
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _readController.close();
  }
}
