import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/conversations_provider.dart';
import '../../../routes/route_names.dart';

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

  static const _notificationFilters = ['Likes', 'Comments', 'Reposts'];
  static const _messageFilters = ['All Messages', 'Unread Messages'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
      if (!_tabController.indexIsChanging && _tabController.index == 1) {
        context.read<ConversationsProvider>().loadConversations();
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Activity'),
        actions: [_buildSettingsButton(context)],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Notifications'), Tab(text: 'Messages')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(
            child: Text('Notifications – $_selectedNotificationFilter'),
          ),
          _buildMessagesTab(),
        ],
      ),
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
                  separatorBuilder: (_, __) => const Divider(height: 1),
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
