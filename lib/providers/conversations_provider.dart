import 'dart:async';
import 'package:flutter/foundation.dart';
import '../features/messages/services/messaging_service.dart';
import '../features/messages/services/socket_service.dart';

// ─────────────────────────────────────────────
// UI-facing models
// ─────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class Conversation {
  final String conversationId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  int unreadCount;
  ChatMessage? lastMessage;
  final DateTime? lastMessageAt;

  Conversation({
    required this.conversationId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageAt,
  });
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

class ConversationsProvider extends ChangeNotifier {
  final MessagingService _messaging;
  final SocketService _socket;

  String? _currentUserId;

  final List<Conversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messagesMap = {};
  final Map<String, String> _userToConvId = {}; // userId → conversationId

  bool isLoading = false;
  bool isLoadingMessages = false;
  String? error;

  StreamSubscription<Map<String, dynamic>>? _msgSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;

  ConversationsProvider(this._messaging, this._socket);

  // ── Public getters ────────────────────────

  List<Conversation> get conversations => List.unmodifiable(_conversations);

  List<Conversation> filtered(String filter) {
    if (filter == 'Unread Messages') {
      return _conversations.where((c) => c.unreadCount > 0).toList();
    }
    return List.unmodifiable(_conversations);
  }

  List<ChatMessage> getMessages(String conversationId) =>
      List.unmodifiable(_messagesMap[conversationId] ?? []);

  // ── Auth lifecycle ────────────────────────

  void setCurrentUser(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    if (userId != null) {
      _initSocket();
      loadConversations();
    } else {
      _cleanUp();
    }
  }

  void _cleanUp() {
    _msgSub?.cancel();
    _readSub?.cancel();
    _socket.disconnect();
    _conversations.clear();
    _messagesMap.clear();
    _userToConvId.clear();
    notifyListeners();
  }

  // ── Socket setup ──────────────────────────

  Future<void> _initSocket() async {
    await _socket.connect();
    _msgSub?.cancel();
    _readSub?.cancel();
    _msgSub = _socket.onMessageNew.listen(_handleIncomingMessage);
    _readSub = _socket.onConversationRead.listen(_handleConversationRead);
  }

  // ── REST: conversations ───────────────────

  Future<void> loadConversations() async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final apiConvs = await _messaging.getConversations();
      _conversations.clear();
      _userToConvId.clear();
      for (final c in apiConvs) {
        if (c.id.isEmpty) continue;
        _userToConvId[c.otherUserId] = c.id;
        final cached = _messagesMap[c.id];
        // Prefer in-memory cached messages; fall back to API-provided last message.
        ChatMessage? lastMessage;
        if (cached != null && cached.isNotEmpty) {
          lastMessage = cached.last;
        } else if (c.lastMessageText != null && c.lastMessageText!.isNotEmpty) {
          final isMe = c.lastMessageSenderId != null &&
              c.lastMessageSenderId!.isNotEmpty &&
              c.lastMessageSenderId != c.otherUserId;
          lastMessage = ChatMessage(
            id: 'api_last_${c.id}',
            text: c.lastMessageText!,
            isMe: isMe,
            timestamp: c.lastMessageAt ?? DateTime.now(),
          );
        }
        _conversations.add(
          Conversation(
            conversationId: c.id,
            userId: c.otherUserId,
            displayName: c.otherDisplayName,
            avatarUrl: c.otherAvatarUrl,
            unreadCount: c.unreadCount,
            lastMessage: lastMessage,
            lastMessageAt: c.lastMessageAt,
          ),
        );
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
      // If the API didn't return last_message data, background-fetch messages
      // for conversations that have activity so the preview shows correctly.
      _prefetchMissingPreviews();
    }
  }

  void _prefetchMissingPreviews() {
    final toFetch = _conversations
        .where((c) => c.lastMessage == null && c.lastMessageAt != null)
        .take(15)
        .map((c) => c.conversationId)
        .toList();
    for (final id in toFetch) {
      _fetchLastMessagePreview(id);
    }
  }

  Future<void> _fetchLastMessagePreview(String conversationId) async {
    try {
      final apiMsgs = await _messaging.getMessages(conversationId);
      if (apiMsgs.isEmpty) return;
      final convIdx = _conversations
          .indexWhere((c) => c.conversationId == conversationId);
      if (convIdx == -1) return;
      final otherUserId = _conversations[convIdx].userId;
      final msgs = apiMsgs
          .map((m) => ChatMessage(
                id: m.id,
                text: m.text,
                isMe: m.senderId != otherUserId,
                timestamp: m.createdAt,
              ))
          .toList();
      _messagesMap[conversationId] = msgs;
      _conversations[convIdx].lastMessage = msgs.last;
      notifyListeners();
    } catch (_) {
      // Best-effort; silently ignore failures.
    }
  }

  /// Returns the conversation ID (creates via API if needed).
  Future<String?> openOrCreate({
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    if (_userToConvId.containsKey(userId)) {
      return _userToConvId[userId];
    }
    try {
      final convId = await _messaging.startOrGetConversation(userId);
      if (convId.isEmpty) return null;
      _userToConvId[userId] = convId;
      if (!_conversations.any((c) => c.userId == userId)) {
        _conversations.insert(
          0,
          Conversation(
            conversationId: convId,
            userId: userId,
            displayName: displayName,
            avatarUrl: avatarUrl,
          ),
        );
        notifyListeners();
      }
      return convId;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── REST: messages ────────────────────────

  Future<void> loadMessages(String conversationId) async {
    isLoadingMessages = true;
    notifyListeners();
    try {
      final apiMsgs = await _messaging.getMessages(conversationId);
      // Determine isMe by comparing against the other participant's _id.
      // Both sender_id and otherUserId come from MongoDB _id fields so they
      // use the same namespace, unlike _currentUserId (from auth user_id).
      final convIdx =
          _conversations.indexWhere((c) => c.conversationId == conversationId);
      final otherUserId =
          convIdx != -1 ? _conversations[convIdx].userId : '';
      _messagesMap[conversationId] = apiMsgs
          .map(
            (m) => ChatMessage(
              id: m.id,
              text: m.text,
              isMe: otherUserId.isNotEmpty
                  ? m.senderId != otherUserId
                  : m.senderId == _currentUserId,
              timestamp: m.createdAt,
            ),
          )
          .toList();

      if (apiMsgs.isNotEmpty) {
        final convIdx = _conversations.indexWhere(
          (c) => c.conversationId == conversationId,
        );
        if (convIdx != -1) {
          _conversations[convIdx].lastMessage =
              _messagesMap[conversationId]!.last;
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingMessages = false;
      notifyListeners();
    }
  }

  // ── Socket: join + mark read ──────────────

  Future<void> joinAndMarkRead(String conversationId) async {
    // Always persist via REST so unread count survives app restarts.
    try {
      await _messaging.markReadRest(conversationId);
    } catch (_) {
      // Best-effort; don't block UI on failure.
    }
    // Also emit via socket for real-time propagation to other devices.
    _socket.joinConversation(conversationId);
    _socket.markRead(conversationId);
    final convIdx = _conversations.indexWhere(
      (c) => c.conversationId == conversationId,
    );
    if (convIdx != -1 && _conversations[convIdx].unreadCount > 0) {
      _conversations[convIdx].unreadCount = 0;
      notifyListeners();
    }
  }

  // ── Send message ──────────────────────────

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final msg = ChatMessage(
      id: tempId,
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );

    // Optimistic update
    final existing = List<ChatMessage>.from(_messagesMap[conversationId] ?? []);
    existing.add(msg);
    _messagesMap[conversationId] = existing;

    final convIdx = _conversations.indexWhere(
      (c) => c.conversationId == conversationId,
    );
    if (convIdx != -1) {
      final conv = _conversations.removeAt(convIdx);
      conv.lastMessage = msg;
      _conversations.insert(0, conv);
    }
    notifyListeners();

    // Prefer socket; fall back to REST
    if (_socket.isConnected) {
      _socket.sendMessage(conversationId, text);
    } else {
      try {
        await _messaging.sendMessageRest(conversationId, text);
      } catch (e) {
        _messagesMap[conversationId]?.removeWhere((m) => m.id == tempId);
        notifyListeners();
        rethrow;
      }
    }
  }

  // ── Socket event handlers ─────────────────

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final rawMsg = data['message'];
    if (rawMsg == null) return;

    final msgData = Map<String, dynamic>.from(rawMsg as Map);
    final convId =
        (data['conversation_id'] ?? msgData['conversation_id'])?.toString();
    if (convId == null || convId.isEmpty) return;

    final msgId = msgData['_id']?.toString() ?? '';
    final senderId = msgData['sender_id']?.toString() ?? '';
    final text = msgData['text']?.toString() ?? '';
    final createdAt =
        DateTime.tryParse(msgData['createdAt']?.toString() ?? '') ??
        DateTime.now();

    final existing = List<ChatMessage>.from(_messagesMap[convId] ?? []);

    // Deduplicate by real server ID
    if (msgId.isNotEmpty && existing.any((m) => m.id == msgId)) return;

    // Use the same namespace as sender_id: compare against the other
    // participant's MongoDB _id, not _currentUserId (from auth user_id).
    final convIdx =
        _conversations.indexWhere((c) => c.conversationId == convId);
    final otherUserId = convIdx != -1 ? _conversations[convIdx].userId : '';
    final isMe = otherUserId.isNotEmpty
        ? senderId != otherUserId
        : senderId == _currentUserId;

    // Replace our optimistic temp message if present
    if (isMe) {
      final tempIdx = existing.indexWhere(
        (m) => m.id.startsWith('temp_') && m.text == text,
      );
      if (tempIdx != -1) {
        existing[tempIdx] =
            ChatMessage(id: msgId, text: text, isMe: true, timestamp: createdAt);
        _messagesMap[convId] = existing;
        notifyListeners();
        return;
      }
    }

    final chatMsg =
        ChatMessage(id: msgId, text: text, isMe: isMe, timestamp: createdAt);
    existing.add(chatMsg);
    _messagesMap[convId] = existing;

    if (convIdx != -1) {
      final conv = _conversations.removeAt(convIdx);
      conv.lastMessage = chatMsg;
      if (!isMe) conv.unreadCount++;
      _conversations.insert(0, conv);
    }
    notifyListeners();
  }

  void _handleConversationRead(Map<String, dynamic> data) {
    // Other participant read our messages — no visible state change needed yet
    notifyListeners();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _readSub?.cancel();
    super.dispose();
  }
}

