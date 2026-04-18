import 'package:flutter/foundation.dart';
import 'package:cross/features/messages/services/message_service.dart';
import 'package:cross/features/messages/models/conversation.dart';
import 'package:cross/features/messages/models/message.dart';
import 'package:cross/features/messages/services/socket_service.dart';

class MessagingProvider with ChangeNotifier {
  final MessageService _messageService;
  final SocketService _socketService;

  MessagingProvider(
    this._messageService,
    this._socketService,
  );

  final Map<String, Conversation> _conversations = {};
  final Map<String, List<Message>> _conversationMessages = {};
  String _currentUserId = '';
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  int _totalUnreadCount = 0;
  String? _errorMessage;
  String? _threadErrorMessage;
  bool _socketConnected = false;

  List<Conversation> get conversations => _conversations.values.toList();
  Map<String, List<Message>> get conversationMessages => _conversationMessages;
  String get currentUserId => _currentUserId;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSendingMessage => _isSendingMessage;
  int get totalUnreadCount => _totalUnreadCount;
  String? get errorMessage => _errorMessage;
  String? get threadErrorMessage => _threadErrorMessage;
  bool get socketConnected => _socketConnected;

  void setCurrentUserId(String userId) {
    final normalizedUserId = userId.trim();
    if (_currentUserId == normalizedUserId) return;
    _currentUserId = normalizedUserId;
    _initializeSocket();
    notifyListeners();
  }

  void _initializeSocket() {
    if (_currentUserId.isEmpty) return;

    _socketService.onMessage(_handleSocketMessage);
    _socketService.onConversationRead(_handleSocketConversationRead);
    _socketService.onConnectionStateChanged(_handleSocketConnectionState);

    _socketService.connect(userId: _currentUserId);
  }

  void _handleSocketMessage(Message message) {
    if (!_conversationMessages.containsKey(message.conversationId)) {
      _conversationMessages[message.conversationId] = [];
    }

    final messages = _conversationMessages[message.conversationId]!;
    if (!messages.any((m) => m.id == message.id)) {
      messages.add(message);
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    if (_conversations.containsKey(message.conversationId)) {
      final conversation = _conversations[message.conversationId]!;
      final isCurrentUserSender = message.senderId == _currentUserId;
      final updatedConversation = conversation.copyWith(
        lastMessage: message,
        lastMessageTime: message.timestamp,
        unreadCount: isCurrentUserSender ? conversation.unreadCount : conversation.unreadCount + 1,
      );
      _conversations[message.conversationId] = updatedConversation;
      if (!isCurrentUserSender) {
        _totalUnreadCount += 1;
      }
    }

    notifyListeners();
  }

  void _handleSocketConversationRead(String conversationId, int markedCount) {
    if (_conversations.containsKey(conversationId)) {
      _totalUnreadCount = (_totalUnreadCount - markedCount).clamp(0, _totalUnreadCount);
      notifyListeners();
    }
  }

  void _handleSocketConnectionState(bool connected) {
    if (_socketConnected != connected) {
      _socketConnected = connected;
      notifyListeners();
    }
  }

  void initializeConversations(List<Conversation> initialConversations) {
    _conversations.clear();
    for (var conversation in initialConversations) {
      _conversations[conversation.id] = conversation;
      _conversationMessages.putIfAbsent(conversation.id, () => []);
    }
    notifyListeners();
  }

  List<Message> getConversationMessages(String conversationId) {
    return List.unmodifiable(_conversationMessages[conversationId] ?? []);
  }

  Conversation? getConversation(String conversationId) {
    return _conversations[conversationId];
  }

  Future<void> fetchConversations({int page = 1, int limit = 20}) async {
    _isLoadingConversations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final conversations = await _messageService.getConversations(
        page: page,
        limit: limit,
      );
      _conversations.clear();
      for (var conversation in conversations) {
        _conversations[conversation.id] = conversation;
        _conversationMessages.putIfAbsent(conversation.id, () => []);
      }
      _totalUnreadCount = await _messageService.getTotalUnreadCount();
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> fetchConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    _isLoadingMessages = true;
    _threadErrorMessage = null;
    notifyListeners();

    try {
      final messages = await _messageService.getChatHistory(
        conversationId,
        page: page,
        limit: limit,
      );
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _conversationMessages[conversationId] = messages;

      await _socketService.joinConversation(conversationId);
    } catch (e) {
      _threadErrorMessage = _parseError(e);
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(
    String conversationId,
    String content, {
    Map<String, dynamic>? sharedEntity,
  }) async {
    if (content.trim().isEmpty) {
      return false;
    }

    final conversation = _conversations[conversationId];
    if (conversation?.isBlocked == true) {
      _threadErrorMessage = 'You have blocked this user. Unblock them to send messages.';
      notifyListeners();
      return false;
    }

    _isSendingMessage = true;
    _threadErrorMessage = null;
    notifyListeners();

    try {
      bool sent = false;

      if (_socketConnected) {
        sent = await _socketService.sendMessage(
          conversationId,
          content.trim(),
          sharedEntity: sharedEntity,
        );
      }

      if (!sent) {
        final sentMessage = await _messageService.sendMessage(
          conversationId,
          content.trim(),
          sharedEntity: sharedEntity,
        );

        if (sentMessage == null) {
          _threadErrorMessage = 'Unable to send message.';
          return false;
        }

        if (!_conversationMessages.containsKey(conversationId)) {
          _conversationMessages[conversationId] = [];
        }
        _conversationMessages[conversationId]!.add(sentMessage);

        if (_conversations.containsKey(conversationId)) {
          final updatedConversation = _conversations[conversationId]!.copyWith(
            lastMessage: sentMessage,
            lastMessageTime: sentMessage.timestamp,
          );
          _conversations[conversationId] = updatedConversation;
        }
      }

      return true;
    } catch (e) {
      _threadErrorMessage = _parseError(e);
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  Future<Conversation?> startOrOpenConversation(String recipientId) async {
    try {
      final conversation = await _messageService.startOrGetConversation(recipientId);
      if (conversation != null) {
        _conversations[conversation.id] = conversation;
        _conversationMessages.putIfAbsent(conversation.id, () => []);
        notifyListeners();
      }
      return conversation;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> markConversationRead(String conversationId) async {
    try {
      bool marked = false;

      if (_socketConnected) {
        marked = await _socketService.markConversationRead(conversationId);
      }

      if (!marked) {
        await _messageService.markConversationRead(conversationId);
      }
      if (_conversations.containsKey(conversationId)) {
        _conversations[conversationId] = _conversations[conversationId]!
            .copyWith(unreadCount: 0);
      }
      _totalUnreadCount = await _messageService.getTotalUnreadCount();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  void receiveMessage(String conversationId, Message message) {
    if (!_conversations.containsKey(conversationId)) return;

    _conversationMessages.putIfAbsent(conversationId, () => []);
    if (!_conversationMessages[conversationId]!.any((m) => m.id == message.id)) {
      _conversationMessages[conversationId]!.add(message);
    }

    final currentConversation = _conversations[conversationId]!;
    final updatedConversation = currentConversation.copyWith(
      lastMessage: message,
      lastMessageTime: message.timestamp,
      unreadCount: currentConversation.unreadCount + 1,
    );
    _conversations[conversationId] = updatedConversation;
    _totalUnreadCount += 1;
    notifyListeners();
  }

  void deleteConversation(String conversationId) {
    _conversations.remove(conversationId);
    _conversationMessages.remove(conversationId);
    notifyListeners();
  }

  void blockUser(String userId) {
    for (var conversationId in _conversations.keys) {
      if (_conversations[conversationId]!.otherUser.id == userId) {
        _conversations[conversationId] =
            _conversations[conversationId]!.copyWith(isBlocked: true);
      }
    }
    notifyListeners();
  }

  void unblockUser(String userId) {
    for (var conversationId in _conversations.keys) {
      if (_conversations[conversationId]!.otherUser.id == userId) {
        _conversations[conversationId] =
            _conversations[conversationId]!.copyWith(isBlocked: false);
      }
    }
    notifyListeners();
  }

  bool isUserBlocked(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return false;

    return _conversations.values.any(
      (conversation) =>
          conversation.otherUser.id.trim() == normalizedUserId &&
          conversation.isBlocked,
    );
  }

  List<Conversation> searchConversations(String query) {
    return _conversations.values
        .where((conv) =>
            conv.otherUser.displayName.toLowerCase().contains(query.toLowerCase()) ||
            conv.otherUser.username.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  String _parseError(dynamic exception) {
    if (exception is Exception) {
      return exception.toString();
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}
