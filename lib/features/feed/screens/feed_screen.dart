import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/conversations_provider.dart';
import '../../../providers/social_provider.dart';
import '../../../routes/route_names.dart';
import '../widgets/track_card.dart';
import '../../player/widgets/mini_player.dart';
import '../models/track.dart';
import '../models/user.dart';

enum ActivityNotificationFilter {
  likes,
  comments,
  reposts,
  followers,
}

enum ActivityMessageFilter {
  all,
  unread,
}

class FeedScreen extends StatefulWidget {
  final bool showBottomNavigationBar;

  const FeedScreen({
    super.key,
    this.showBottomNavigationBar = false,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  ActivityNotificationFilter _notificationFilter =
      ActivityNotificationFilter.likes;
  ActivityMessageFilter _messageFilter = ActivityMessageFilter.all;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) return;
        setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchActivityFeed();
      context.read<FeedProvider>().fetchTrendingTracks();
      context.read<ConversationsProvider>().loadConversations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTrackList(
    BuildContext context,
    FeedProvider provider,
    List<Track> tracks,
    String emptyMessage,
    bool isLoading,
  ) {
    if (isLoading && tracks.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (provider.error != null && tracks.isEmpty) {
      return Center(child: Text('Error: ${provider.error}'));
    }

    if (tracks.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      itemCount: tracks.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: track.uploader?.profileImageUrl != null
                        ? NetworkImage(track.uploader!.profileImageUrl!)
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    radius: 12,
                    child: track.uploader?.profileImageUrl == null
                        ? Icon(
                            Icons.person,
                            size: 12,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${track.uploader?.displayName ?? 'Unknown User'} uploaded a new track',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Navigate to user profile
                    },
                    child: Text(
                      'View Profile',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TrackCard(
                track: track,
                onPlay: () {
                  context.read<PlayerProvider>().playTrack(
                    track,
                    playlist: tracks,
                  );
                },
                onDetails: () {
                  Navigator.of(
                    context,
                  ).pushNamed(RouteNames.trackDetails, arguments: track);
                },
                onLikeToggle: () =>
                    context.read<FeedProvider>().toggleLike(track),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text('Activity'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Notifications'),
              Tab(text: 'Messages'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings_outlined),
              onSelected: (value) {
                setState(() {
                  switch (value) {
                    case 'notif_likes':
                      _notificationFilter = ActivityNotificationFilter.likes;
                      break;
                    case 'notif_comments':
                      _notificationFilter = ActivityNotificationFilter.comments;
                      break;
                    case 'notif_reposts':
                      _notificationFilter = ActivityNotificationFilter.reposts;
                      break;
                    case 'notif_followers':
                      _notificationFilter = ActivityNotificationFilter.followers;
                      break;
                    case 'msg_all':
                      _messageFilter = ActivityMessageFilter.all;
                      break;
                    case 'msg_unread':
                      _messageFilter = ActivityMessageFilter.unread;
                      break;
                  }
                });
              },
              itemBuilder: (context) {
                final isNotificationsTab = _tabController.index == 0;
                if (isNotificationsTab) {
                  return [
                    PopupMenuItem<String>(
                      value: 'notif_likes',
                      child: _buildFilterMenuItem(
                        label: 'Likes',
                        isSelected:
                            _notificationFilter == ActivityNotificationFilter.likes,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'notif_comments',
                      child: _buildFilterMenuItem(
                        label: 'Comments',
                        isSelected: _notificationFilter ==
                            ActivityNotificationFilter.comments,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'notif_reposts',
                      child: _buildFilterMenuItem(
                        label: 'Reposts',
                        isSelected: _notificationFilter ==
                            ActivityNotificationFilter.reposts,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'notif_followers',
                      child: _buildFilterMenuItem(
                        label: 'Followers',
                        isSelected: _notificationFilter ==
                            ActivityNotificationFilter.followers,
                      ),
                    ),
                  ];
                }

                return [
                  PopupMenuItem<String>(
                    value: 'msg_all',
                    child: _buildFilterMenuItem(
                      label: 'All messages',
                      isSelected: _messageFilter == ActivityMessageFilter.all,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'msg_unread',
                    child: _buildFilterMenuItem(
                      label: 'Unread messages',
                      isSelected: _messageFilter == ActivityMessageFilter.unread,
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Notifications Tab
                  _buildNotificationsTab(context),
                  // Messages Tab
                  _buildMessagesTab(context),
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        ),
        bottomNavigationBar: widget.showBottomNavigationBar
            ? _buildBottomNavigationBar(context)
            : null,
    );
  }

  Widget _buildFilterMenuItem({
    required String label,
    required bool isSelected,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: isSelected
              ? const Icon(Icons.check, size: 18)
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  void _refreshActivityPage() {
    context.read<FeedProvider>().fetchActivityFeed();
    context.read<FeedProvider>().fetchTrendingTracks();
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a1a),
        border: Border(top: BorderSide(color: Color(0xFF333333), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _navItem(
              icon: Icons.home,
              label: 'Home',
              onTap: () {
                Navigator.of(context).pushReplacementNamed(
                  RouteNames.mainScreen,
                  arguments: 0,
                );
              },
            ),
            _navItem(
              icon: Icons.search,
              label: 'Search',
              onTap: () {
                Navigator.of(context).pushReplacementNamed(
                  RouteNames.mainScreen,
                  arguments: 1,
                );
              },
            ),
            _navItem(
              icon: Icons.library_music,
              label: 'Library',
              onTap: () {
                Navigator.of(context).pushReplacementNamed(
                  RouteNames.mainScreen,
                  arguments: 2,
                );
              },
            ),
            _navItem(
              icon: Icons.dynamic_feed,
              label: 'Feed',
              onTap: () {
                _refreshActivityPage();
              },
            ),
            _navItem(
              icon: Icons.workspace_premium,
              label: 'Upgrade',
              onTap: () {
                Navigator.of(context).pushReplacementNamed(
                  RouteNames.mainScreen,
                  arguments: 4,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF888888), size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsTab(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        final filteredNotifications =
            _applyNotificationFilter(provider.activityFeed);

        return _buildTrackList(
          context,
          provider,
          filteredNotifications,
          _notificationEmptyMessage(),
          provider.isLoading,
        );
      },
    );
  }

  List<Track> _applyNotificationFilter(List<Track> tracks) {
    switch (_notificationFilter) {
      case ActivityNotificationFilter.likes:
        return tracks
            .where((track) => track.isLiked || track.likeCount > 0)
            .toList();
      case ActivityNotificationFilter.comments:
        return tracks.where((track) => track.commentCount > 0).toList();
      case ActivityNotificationFilter.reposts:
        return tracks
            .where((track) => track.isReposted || track.repostCount > 0)
            .toList();
      case ActivityNotificationFilter.followers:
        return tracks
            .where((track) =>
                (track.uploader?.followersCount ?? 0) > 0 &&
                (track.uploader?.id.isNotEmpty ?? false))
            .toList();
    }
  }

  String _notificationEmptyMessage() {
    switch (_notificationFilter) {
      case ActivityNotificationFilter.likes:
        return 'No like notifications yet';
      case ActivityNotificationFilter.comments:
        return 'No comment notifications yet';
      case ActivityNotificationFilter.reposts:
        return 'No repost notifications yet';
      case ActivityNotificationFilter.followers:
        return 'No follower notifications yet';
    }
  }

  Widget _buildMessagesTab(BuildContext context) {
    return Consumer<ConversationsProvider>(
      builder: (context, messagingProvider, child) {
        final allConversations = messagingProvider.conversations;
        final conversations = _messageFilter == ActivityMessageFilter.unread
            ? allConversations
                .where((conversation) => conversation.unreadCount > 0)
                .toList()
            : allConversations;

        if (messagingProvider.isLoading &&
            allConversations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (messagingProvider.error != null && allConversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                messagingProvider.error!,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (conversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _messageFilter == ActivityMessageFilter.unread
                        ? 'No Unread Messages'
                        : 'No Messages Yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _messageFilter == ActivityMessageFilter.unread
                        ? 'All conversations are read right now.'
                        : 'Start a conversation with artists and users you follow',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_messageFilter == ActivityMessageFilter.all)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(RouteNames.search);
                      },
                      child: const Text('Find Artists to Follow'),
                    ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: conversations.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: Theme.of(context).colorScheme.outline),
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _buildConversationTile(context, conversation);
          },
        );
      },
    );
  }

  Widget _buildConversationTile(
      BuildContext context, Conversation conversation) {
    final timeString =
        _formatMessageTime(conversation.lastMessageAt ?? DateTime.now());

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: conversation.avatarUrl != null
            ? NetworkImage(conversation.avatarUrl!)
            : null,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: conversation.avatarUrl == null
            ? Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : null,
      ),
      title: Text(
        conversation.displayName,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage != null
            ? (conversation.lastMessage!.isMe
                ? 'You: ${conversation.lastMessage!.text}'
                : '${conversation.displayName}: ${conversation.lastMessage!.text}')
            : 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.6),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeString,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.of(context).pushNamed(
          RouteNames.chat,
          arguments: {
            'userId': conversation.userId,
            'displayName': conversation.displayName,
            'avatarUrl': conversation.avatarUrl,
          },
        );
      },
      onLongPress: () {
        _showConversationOptions(context, conversation);
      },
    );
  }

  void _showConversationOptions(
      BuildContext context, Conversation conversation) {
    final socialProvider = context.read<SocialProvider>();
    final isBlocked = socialProvider.isUserBlocked(conversation.userId);

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
              Navigator.of(context).pushNamed(
                RouteNames.publicProfile,
                arguments: conversation.userId,
              );
            },
          ),
          if (!isBlocked)
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () async {
                Navigator.pop(context);
                await socialProvider.blockUser(conversation.userId);
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
                await socialProvider.unblockUser(conversation.userId);
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

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
