import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/social/models/relationship_status_model.dart';
import 'package:cross/features/social/widgets/avatar_url_utils.dart';
import 'package:cross/features/social/widgets/follow_action_button.dart';
import 'package:cross/features/social/widgets/social_list_state_view.dart';
import 'package:cross/features/upload/models/upload_model.dart';
import 'package:cross/providers/messaging_provider.dart';
import 'package:cross/providers/upload_provider.dart';
import 'package:cross/providers/social_provider.dart';
import 'package:cross/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialProvider>().loadPublicProfile(widget.userId);
      _loadUploadedTracks(replace: true);
    });
  }

  @override
  void didUpdateWidget(covariant PublicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId == widget.userId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialProvider>().loadPublicProfile(widget.userId);
      _loadUploadedTracks(replace: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialProvider>(
      builder: (context, provider, _) {
        final profile = provider.publicProfile;
        final relation = provider.relationshipStatus;
        final hasValidAvatar = isValidNetworkAvatarUrl(profile?.avatarUrl);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text('Profile'),
          ),
          body: provider.isLoadingProfile && profile == null
              ? const Center(child: CircularProgressIndicator())
              : profile == null
                  ? SocialListStateView(
                      icon: Icons.person_off,
                      title: 'Profile unavailable',
                      message: provider.profileError ?? 'Could not load this user.',
                      actionLabel: 'Retry',
                      onAction: () => provider.loadPublicProfile(widget.userId),
                    )
                  : DefaultTabController(
                      length: 3,
                      child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 58,
                                          backgroundColor: AppColors.surfaceElevated,
                                          backgroundImage: hasValidAvatar
                                              ? NetworkImage(profile.avatarUrl.trim())
                                              : null,
                                          child: !hasValidAvatar
                                              ? const Icon(Icons.person, size: 44, color: AppColors.iconSecondary)
                                              : null,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          profile.displayName,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '@${profile.username}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (profile.bio.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            profile.bio,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: AppColors.textSecondary),
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        _buildRelationActions(provider, relation),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStatsRow(
                                    context: context,
                                    targetUserId: profile.id,
                                    followers: profile.followersCount,
                                    following: profile.followingCount,
                                    tracks: profile.trackCount,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _TabBarHeader(
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                tabBar: const TabBar(
                                  indicatorColor: AppColors.primary,
                                  labelColor: AppColors.primary,
                                  unselectedLabelColor: AppColors.textSecondary,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  unselectedLabelStyle: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  tabs: [
                                    Tab(text: 'Uploaded'),
                                    Tab(text: 'Playlists'),
                                    Tab(text: 'Favorite Genre'),
                                  ],
                                ),
                              ),
                            ),
                          ];
                        },
                        body: TabBarView(
                          children: [
                            _buildUploadedTracksSection(),
                            _buildSection('Playlists', profile.playlists),
                            _buildSection('Favorite Genres', profile.favoriteGenres),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }

  Future<void> _loadUploadedTracks({bool replace = true}) {
    return context.read<UploadProvider>().loadArtistTracks(
      artistId: widget.userId,
      page: 1,
      limit: 20,
      replace: replace,
    );
  }

  Future<void> _loadMoreUploadedTracks() {
    return context.read<UploadProvider>().loadNextArtistTracks(
      artistId: widget.userId,
      limit: 20,
    );
  }

  Widget _buildRelationActions(SocialProvider provider, RelationshipStatusModel? relation) {
    final status = relation;
    if (status == null) {
      return const SizedBox.shrink();
    }

    if (status.isBlockedByThem) {
      return const Chip(
        label: Text('You are blocked'),
        backgroundColor: AppColors.surfaceElevated,
      );
    }

    if (status.isBlockedByMe) {
      return FollowActionButton(
        label: 'Unblock',
        active: true,
        isLoading: provider.isMutatingRelationship,
        onPressed: () => provider.unblockUser(widget.userId),
      );
    }

    final isSelf = provider.currentUserId == widget.userId;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FollowActionButton(
          label: status.followLabel,
          active: !status.isFollowing,
          isLoading: provider.isMutatingRelationship,
          onPressed: () => provider.toggleFollowState(widget.userId),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: provider.isMutatingRelationship
              ? null
              : () => provider.blockUser(widget.userId),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
          ),
          child: const Text('Block'),
        ),
        if (!isSelf) ...[
          const SizedBox(width: 8),
          _ChatActionButton(targetUserId: widget.userId),
        ],
      ],
    );
  }

  Widget _buildStatsRow({
    required BuildContext context,
    required String targetUserId,
    required int followers,
    required int following,
    required int tracks,
  }) {
    final theme = Theme.of(context);

    Widget stat(String label, int value, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  '$value',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        stat(
          'Followers',
          followers,
          () => Navigator.pushNamed(
            context,
            RouteNames.followers,
            arguments: targetUserId,
          ),
        ),
        const SizedBox(width: 12),
        stat(
          'Following',
          following,
          () => Navigator.pushNamed(
            context,
            RouteNames.following,
            arguments: targetUserId,
          ),
        ),
        const SizedBox(width: 12),
        stat('Tracks', tracks, () {}),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items) {
    if (items.isEmpty) {
      return const SocialListStateView(
        icon: Icons.library_music_outlined,
        title: 'No items yet',
        message: 'Nothing to show in this tab right now.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.music_note, color: AppColors.iconSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadedTracksSection() {
    return Consumer<UploadProvider>(
      builder: (context, uploadProvider, _) {
        final isTrackLoadOperation =
            uploadProvider.currentOperation == 'loadArtistTracks';
        final isLoadingTracks = uploadProvider.isLoading && isTrackLoadOperation;
        final tracks = uploadProvider.publicArtistTracksForUser(widget.userId);

        if (isLoadingTracks && tracks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (uploadProvider.errorMessage != null && tracks.isEmpty) {
          return SocialListStateView(
            icon: Icons.music_off,
            title: 'Could not load uploaded tracks',
            message: uploadProvider.errorMessage!,
            actionLabel: 'Retry',
            onAction: () => _loadUploadedTracks(replace: true),
          );
        }

        if (tracks.isEmpty) {
          return const SocialListStateView(
            icon: Icons.library_music_outlined,
            title: 'No items yet',
            message: 'Nothing to show in this tab right now.',
          );
        }

        final showLoadMore = uploadProvider.publicArtistHasMoreForUser(widget.userId);
        final showLoadingMore = isLoadingTracks && tracks.isNotEmpty;
        final itemCount = tracks.length + ((showLoadMore || showLoadingMore) ? 1 : 0);

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index >= tracks.length) {
              if (showLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return Center(
                child: OutlinedButton(
                  onPressed: _loadMoreUploadedTracks,
                  child: const Text('Load more'),
                ),
              );
            }

            final track = tracks[index];
            return _buildUploadedTrackItem(track);
          },
        );
      },
    );
  }

  Widget _buildUploadedTrackItem(UploadModel track) {
    final hasArtwork = isValidNetworkAvatarUrl(track.artworkPathOrUrl);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              image: hasArtwork
                  ? DecorationImage(
                      image: NetworkImage(track.artworkPathOrUrl.trim()),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !hasArtwork
                ? const Icon(Icons.music_note, color: AppColors.iconSecondary)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.genre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatActionButton extends StatelessWidget {
  const _ChatActionButton({required this.targetUserId});

  final String targetUserId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final messagingProvider = context.read<MessagingProvider>();
        final conversation = await messagingProvider.startOrOpenConversation(targetUserId);

        if (conversation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open chat.')),
          );
          return;
        }

        if (!context.mounted) return;

        Navigator.pushNamed(
          context,
          RouteNames.messageThread,
          arguments: conversation,
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
      ),
      icon: const Icon(Icons.chat_bubble_outline),
      label: const Text('Message'),
    );
  }
}

class _TabBarHeader extends SliverPersistentHeaderDelegate {
  _TabBarHeader({required this.tabBar, required this.backgroundColor});

  final TabBar tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarHeader oldDelegate) {
    return oldDelegate.tabBar != tabBar ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
