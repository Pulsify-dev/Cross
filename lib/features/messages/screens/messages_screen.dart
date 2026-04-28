import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/conversations_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../routes/route_names.dart';
import '../models/notification_model.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selected filters per tab
  String _selectedNotificationFilter = 'Likes';
  String _selectedMessageFilter = 'All Messages';

  static const _notificationFilters = ['Likes', 'Comments', 'Reposts', 'Followers'];
  static const _messageFilters = ['All Messages', 'Unread Messages'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationsProvider = context.read<NotificationsProvider>();
      if (notificationsProvider.notifications.isEmpty) {
        notificationsProvider.refresh();
      }
    });
    _tabController.addListener(() {
      setState(() {});
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1) {
          context.read<ConversationsProvider>().loadConversations();
        } else {
          final notificationsProvider = context.read<NotificationsProvider>();
          if (notificationsProvider.notifications.isEmpty) {
            notificationsProvider.refresh();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isNotificationsTab => _tabController.index == 0;

  List<String> get _currentFilters =>
      _isNotificationsTab ? _notificationFilters : _messageFilters;

  String get _currentSelection => _isNotificationsTab
      ? _selectedNotificationFilter
      : _selectedMessageFilter;

  void _onFilterSelected(String value) {
    setState(() {
      if (_isNotificationsTab) {
        _selectedNotificationFilter = value;
      } else {
        _selectedMessageFilter = value;
      }
    });
  }

  Widget _buildSettingsButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings),
      onSelected: _onFilterSelected,
      itemBuilder: (context) => _currentFilters
          .map(
            (filter) => PopupMenuItem<String>(
              value: filter,
              child: Row(
                children: [
                  Expanded(child: Text(filter)),
                  if (filter == _currentSelection)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<NotificationsProvider, int>(
      (p) => p.unreadCount,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Activity'),
        actions: [
          if (_isNotificationsTab)
            TextButton(
              onPressed: unreadCount > 0
                  ? () => context.read<NotificationsProvider>().markAllAsRead()
                  : null,
              child: const Text('Mark all as read'),
            ),
          _buildSettingsButton(context),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Notifications'), Tab(text: 'Messages')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsTab(),
          _buildMessagesTab(),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return Consumer<NotificationsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = provider.filtered(_selectedNotificationFilter);

        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    'No $_selectedNotificationFilter notifications yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scroll) {
            if (scroll.metrics.pixels >=
                scroll.metrics.maxScrollExtent - 160) {
              provider.loadMore();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length + (provider.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final notification = items[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () {
                    context.read<NotificationsProvider>().markAsRead(
                      notification.id,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    return Consumer<ConversationsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversations = provider.filtered(_selectedMessageFilter);

        return RefreshIndicator(
          onRefresh: provider.loadConversations,
          child: conversations.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Text(
                        _selectedMessageFilter == 'Unread Messages'
                            ? 'No Unread Messages'
                            : 'No messages yet.\nFind a user and start chatting!',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final last = conv.lastMessage;
                    final hasAvatar =
                        conv.avatarUrl != null &&
                        conv.avatarUrl!.trim().isNotEmpty;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        backgroundImage: hasAvatar
                            ? NetworkImage(conv.avatarUrl!.trim())
                            : null,
                        child: !hasAvatar
                            ? Text(
                                conv.displayName.isNotEmpty
                                    ? conv.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        conv.displayName,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: last != null
                          ? Text(
                              last.isMe
                                  ? 'You: ${last.text}'
                                  : '${conv.displayName}: ${last.text}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const Text(
                              'No messages yet',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                      trailing: conv.unreadCount > 0
                          ? CircleAvatar(
                              radius: 10,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: Text(
                                '${conv.unreadCount}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          RouteNames.chat,
                          arguments: {
                            'userId': conv.userId,
                            'displayName': conv.displayName,
                            'avatarUrl': conv.avatarUrl,
                          },
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar =
        notification.actorAvatarUrl != null &&
        notification.actorAvatarUrl!.trim().isNotEmpty;

    return ListTile(
      onTap: onTap,
      tileColor: notification.isRead
          ? null
          : theme.colorScheme.primary.withValues(alpha: 0.08),
      leading: CircleAvatar(
        backgroundImage:
            hasAvatar ? NetworkImage(notification.actorAvatarUrl!.trim()) : null,
        child: !hasAvatar
            ? Text(
                notification.actorDisplayName.isNotEmpty
                    ? notification.actorDisplayName[0].toUpperCase()
                    : '?',
              )
            : null,
      ),
      title: Text(
        '${notification.actorDisplayName} ${notification.actionType.label}',
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
        ),
      ),
      subtitle: Text(_relativeTime(notification.createdAt)),
      trailing: notification.isRead
          ? null
          : CircleAvatar(
              radius: 5,
              backgroundColor: theme.colorScheme.primary,
            ),
    );
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}
