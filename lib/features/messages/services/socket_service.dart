import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/session_service.dart';
import '../models/message.dart';

typedef OnMessageCallback = void Function(Message message);
typedef OnConversationReadCallback = void Function(String conversationId, int markedCount);
typedef OnConnectionStateCallback = void Function(bool connected);

class SocketService {
  final SessionService _sessionService;
  late IO.Socket _socket;

  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentUserId;

  final Map<String, dynamic> _messageCache = {};
  final List<OnMessageCallback> _messageListeners = [];
  final List<OnConversationReadCallback> _readListeners = [];
  final List<OnConnectionStateCallback> _connectionListeners = [];

  SocketService(this._sessionService);

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  Future<void> connect({required String userId}) async {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;
    _currentUserId = userId;
    _notifyConnectionState(false);

    try {
      final accessToken = await _sessionService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        _isConnecting = false;
        _notifyConnectionState(false);
        return;
      }

      final socketUrl = ApiConstants.baseUrl.replaceFirst('/v1', '');

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth(<String, dynamic>{'token': 'Bearer $accessToken'})
            .build(),
      );

      _setupEventListeners();
    } catch (e) {
      if (kDebugMode) print('Socket connection error: $e');
      _isConnecting = false;
      _notifyConnectionState(false);
    }
  }

  void _setupEventListeners() {
    _socket.on('connect', (_) {
      _isConnected = true;
      _isConnecting = false;
      _notifyConnectionState(true);
      if (kDebugMode) print('[Socket] Connected');
    });

    _socket.on('disconnect', (_) {
      _isConnected = false;
      _notifyConnectionState(false);
      if (kDebugMode) print('[Socket] Disconnected');
    });

    _socket.on('connect_error', (error) {
      if (kDebugMode) print('[Socket] Connection error: $error');
      _isConnected = false;
      _isConnecting = false;
      _notifyConnectionState(false);
    });

    _socket.on('message:new', (data) {
      if (data is Map) {
        _handleNewMessage(data.cast<String, dynamic>());
      }
    });

    _socket.on('conversation:read', (data) {
      if (data is Map) {
        _handleConversationRead(data.cast<String, dynamic>());
      }
    });
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = data['message'];
      if (message is Map<String, dynamic>) {
        final messageIdValue = message['_id'] ?? message['id'];
        final messageId = messageIdValue is String ? messageIdValue.toString() : (messageIdValue?.toString() ?? '');

        if (messageId.isEmpty || _messageCache.containsKey(messageId)) {
          if (kDebugMode) print('[Socket] Message deduped: $messageId');
          return;
        }

        _messageCache[messageId] = true;

        final parsedMessage = Message.fromJson(message);
        for (var listener in _messageListeners) {
          listener(parsedMessage);
        }
        if (kDebugMode) print('[Socket] New message: $messageId');
      }
    } catch (e) {
      if (kDebugMode) print('[Socket] Error handling message: $e');
    }
  }

  void _handleConversationRead(Map<String, dynamic> data) {
    try {
      final conversationIdValue = data['conversation_id'];
      final conversationId = conversationIdValue is String ? conversationIdValue : '';
      final markedCountValue = data['marked_count'];
      final markedCount = markedCountValue is int ? markedCountValue : 0;

      for (var listener in _readListeners) {
        listener(conversationId, markedCount);
      }
      if (kDebugMode) print('[Socket] Conversation read: $conversationId');
    } catch (e) {
      if (kDebugMode) print('[Socket] Error handling read: $e');
    }
  }

  Future<bool> joinConversation(String conversationId) async {
    if (!_isConnected) return false;

    try {
      _socket.emit('conversation:join', <String, dynamic>{
        'conversation_id': conversationId,
      });
      if (kDebugMode) print('[Socket] Joined conversation: $conversationId');
      return true;
    } catch (e) {
      if (kDebugMode) print('[Socket] Error joining conversation: $e');
      return false;
    }
  }

  Future<bool> sendMessage(
    String conversationId,
    String text, {
    Map<String, dynamic>? sharedEntity,
  }) async {
    if (!_isConnected) return false;

    try {
      final payload = <String, dynamic>{
        'conversation_id': conversationId,
        'text': text,
      };

      if (sharedEntity != null && sharedEntity.isNotEmpty) {
        payload['shared_entity'] = sharedEntity;
      }

      _socket.emit('message:new', payload);
      if (kDebugMode) print('[Socket] Message sent: $conversationId');
      return true;
    } catch (e) {
      if (kDebugMode) print('[Socket] Error sending message: $e');
      return false;
    }
  }

  Future<bool> markConversationRead(String conversationId) async {
    if (!_isConnected) return false;

    try {
      _socket.emit('conversation:read', <String, dynamic>{
        'conversation_id': conversationId,
      });
      if (kDebugMode) print('[Socket] Marked read: $conversationId');
      return true;
    } catch (e) {
      if (kDebugMode) print('[Socket] Error marking read: $e');
      return false;
    }
  }

  void onMessage(OnMessageCallback callback) {
    _messageListeners.add(callback);
  }

  void onConversationRead(OnConversationReadCallback callback) {
    _readListeners.add(callback);
  }

  void onConnectionStateChanged(OnConnectionStateCallback callback) {
    _connectionListeners.add(callback);
  }

  void _notifyConnectionState(bool connected) {
    for (var listener in _connectionListeners) {
      listener(connected);
    }
  }

  void removeListener(dynamic callback) {
    _messageListeners.remove(callback);
    _readListeners.remove(callback);
    _connectionListeners.remove(callback);
  }

  Future<void> disconnect() async {
    try {
      if (_socket.connected) {
        _socket.disconnect();
      }
      _isConnected = false;
      _isConnecting = false;
      _messageCache.clear();
      _notifyConnectionState(false);
      if (kDebugMode) print('[Socket] Disconnected');
    } catch (e) {
      if (kDebugMode) print('[Socket] Error during disconnect: $e');
    }
  }

  void dispose() {
    disconnect();
    _messageListeners.clear();
    _readListeners.clear();
    _connectionListeners.clear();
  }
}
