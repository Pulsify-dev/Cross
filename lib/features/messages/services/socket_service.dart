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
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Callbacks registered to run once the socket connects.
  final List<VoidCallback> _onConnectQueue = [];

  SocketService({SessionService? sessionService})
      : _sessionService = sessionService ?? SessionService();

  Stream<Map<String, dynamic>> get onMessageNew => _messageController.stream;
  Stream<Map<String, dynamic>> get onConversationRead => _readController.stream;
  Stream<Map<String, dynamic>> get onNotificationNew =>
      _notificationController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected ?? false) return;

    final token = await _sessionService.getAccessToken();
    if (token == null || token.isEmpty) return;

    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setAuth({'token': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('connect', (_) {
      // Flush any deferred room-join calls that arrived before the handshake.
      for (final cb in _onConnectQueue) {
        cb();
      }
      _onConnectQueue.clear();
    });

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

    _socket!.on('new_notification', (data) {
      if (data is Map && !_notificationController.isClosed) {
        _notificationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  /// Joins the conversation room immediately if connected, or defers until
  /// the socket connects.
  void joinConversation(String conversationId) {
    if (isConnected) {
      _emitJoin(conversationId);
    } else {
      _onConnectQueue.add(() => _emitJoin(conversationId));
    }
  }

  void _emitJoin(String conversationId) {
    _socket?.emitWithAck(
      'conversation:join',
      {'conversation_id': conversationId},
      ack: (_) {},
    );
  }

  /// Sends a message via socket and calls [onAck] with the server's
  /// acknowledgment payload so the caller can replace the temp ID.
  void sendMessage(
    String conversationId,
    String text, {
    void Function(Map<String, dynamic> ack)? onAck,
  }) {
    _socket?.emitWithAck(
      'message:new',
      {'conversation_id': conversationId, 'text': text},
      ack: (data) {
        if (onAck != null && data is Map) {
          onAck(Map<String, dynamic>.from(data));
        }
      },
    );
  }

  void markRead(String conversationId) {
    _socket?.emitWithAck(
      'conversation:read',
      {'conversation_id': conversationId},
      ack: (_) {},
    );
  }

  void joinNotifications() {
    _socket?.emitWithAck('join_notifications', null, ack: (_) {});
  }

  void leaveNotifications() {
    _socket?.emitWithAck('leave_notifications', null, ack: (_) {});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _onConnectQueue.clear();
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _readController.close();
    _notificationController.close();
  }
}

typedef VoidCallback = void Function();
