import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/messaging_provider.dart';
import '../../../providers/social_provider.dart';
import '../../../routes/route_names.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class MessageThreadScreen extends StatefulWidget {
  final Conversation conversation;

  const MessageThreadScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final messagingProvider = context.read<MessagingProvider>();
      final socialProvider = context.read<SocialProvider>();
      final existingMessages = messagingProvider.getConversationMessages(widget.conversation.id);

      if (existingMessages.isEmpty) {
        await messagingProvider.fetchConversationMessages(widget.conversation.id);
      }

      await socialProvider.loadBlockedUsers();
      await messagingProvider.markConversationRead(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final socialProvider = context.read<SocialProvider>();
    final messagingProvider = context.read<MessagingProvider>();
    final otherUserId = widget.conversation.otherUser.id.trim();
    final isBlocked = socialProvider.isUserBlocked(otherUserId) ||
        messagingProvider.isUserBlocked(otherUserId);

    if (isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have blocked this user. Unblock them to send messages.'),
        ),
      );
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    final success = await messagingProvider.sendMessage(widget.conversation.id, message);

    if (!success) {
      final error = context.read<MessagingProvider>().threadErrorMessage ??
          'Failed to send message. Please try again.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  widget.conversation.otherUser.profileImageUrl != null
                      ? NetworkImage(
                          widget.conversation.otherUser.profileImageUrl!)
                      : null,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: widget.conversation.otherUser.profileImageUrl == null
                  ? Icon(
                      Icons.person,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.otherUser.displayName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Online',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer2<MessagingProvider, SocialProvider>(
              builder: (context, messagingProvider, socialProvider, child) {
                final messages = messagingProvider.getConversationMessages(widget.conversation.id);
                final isLoading = messagingProvider.isLoadingMessages && messages.isEmpty;
                final currentUserId = messagingProvider.currentUserId.trim();
                final otherUserId = widget.conversation.otherUser.id.trim();

                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messagingProvider.threadErrorMessage != null && messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        messagingProvider.threadErrorMessage!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No messages in this conversation yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isCurrentUser = _isCurrentUserMessage(
                      message,
                      currentUserId: currentUserId,
                      otherUserId: otherUserId,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isCurrentUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isCurrentUser)
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: widget.conversation.otherUser.profileImageUrl != null
                                  ? NetworkImage(widget.conversation.otherUser.profileImageUrl!)
                                  : null,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: widget.conversation.otherUser.profileImageUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 12,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    )
                                  : null,
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(18),
                                border: isCurrentUser
                                    ? null
                                    : Border.all(
                                        color: Theme.of(context).colorScheme.outline,
                                        width: 0.5,
                                      ),
                              ),
                              child: Column(
                                crossAxisAlignment: isCurrentUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(message.timestamp),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: isCurrentUser
                                              ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)
                                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isCurrentUser) const SizedBox(width: 8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Consumer2<MessagingProvider, SocialProvider>(
            builder: (context, messagingProvider, socialProvider, _) {
              final otherUserId = widget.conversation.otherUser.id.trim();
              final latestConversation =
                  messagingProvider.getConversation(widget.conversation.id) ??
                      widget.conversation;
              final isBlocked = latestConversation.isBlocked ||
                  socialProvider.isUserBlocked(otherUserId);

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isBlocked)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'This user is blocked. Unblock them to send messages.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: isBlocked
                              ? null
                              : () {
                                  // TODO: Show options to share track, playlist, or attach file
                                },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            readOnly: isBlocked,
                            decoration: InputDecoration(
                              hintText: isBlocked
                                  ? 'Unblock this user to send a message'
                                  : 'Type your message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.8),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: isBlocked ? null : (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: isBlocked ? null : _sendMessage,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isCurrentUserMessage(
    Message message, {
    required String currentUserId,
    required String otherUserId,
  }) {
    final senderId = message.senderId.trim();
    final receiverId = message.receiverId.trim();

    if (senderId.isNotEmpty) {
      if (otherUserId.isNotEmpty && senderId == otherUserId) {
        return false;
      }
      if (currentUserId.isNotEmpty && senderId == currentUserId) {
        return true;
      }
      return true;
    }

    if (receiverId.isNotEmpty) {
      if (currentUserId.isNotEmpty && receiverId == currentUserId) {
        return false;
      }
      if (otherUserId.isNotEmpty && receiverId == otherUserId) {
        return true;
      }
    }

    return false;
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showMoreOptions(BuildContext context) {
    final messagingProvider = context.read<MessagingProvider>();
    final socialProvider = context.read<SocialProvider>();
    final latestConversation =
        messagingProvider.getConversation(widget.conversation.id) ??
            widget.conversation;
    final isBlocked = latestConversation.isBlocked ||
        socialProvider.isUserBlocked(widget.conversation.otherUser.id);

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(this.context).pushNamed(
                RouteNames.publicProfile,
                arguments: widget.conversation.otherUser.id,
              );
            },
          ),
          if (!isBlocked)
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () async {
                Navigator.pop(context);
                await socialProvider.blockUser(widget.conversation.otherUser.id);
                messagingProvider.blockUser(widget.conversation.otherUser.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User blocked')),
                );
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Unblock User'),
              onTap: () async {
                Navigator.pop(context);
                await socialProvider.unblockUser(widget.conversation.otherUser.id);
                messagingProvider.unblockUser(widget.conversation.otherUser.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User unblocked')),
                );
              },
            ),
        ],
      ),
    );
  }
}
