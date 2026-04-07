import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/social/models/relationship_status_model.dart';
import 'package:cross/features/social/widgets/follow_action_button.dart';
import 'package:cross/features/social/widgets/social_list_state_view.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialProvider>(
      builder: (context, provider, _) {
        final profile = provider.publicProfile;
        final relation = provider.relationshipStatus;

        return Scaffold(
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
                  : CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 220,
                          pinned: true,
                          backgroundColor: AppColors.background,
                          flexibleSpace: FlexibleSpaceBar(
                            background: _buildCover(profile.coverUrl),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -40),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      CircleAvatar(
                                        radius: 44,
                                        backgroundColor: AppColors.surfaceElevated,
                                        backgroundImage: profile.avatarUrl.isNotEmpty
                                            ? NetworkImage(profile.avatarUrl)
                                            : null,
                                        child: profile.avatarUrl.isEmpty
                                            ? const Icon(Icons.person, size: 34)
                                            : null,
                                      ),
                                      const Spacer(),
                                      _buildRelationActions(provider, relation),
                                    ],
                                  ),
                                ),
                                Text(
                                  profile.displayName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
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
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                _buildStatsRow(
                                  followers: profile.followersCount,
                                  following: profile.followingCount,
                                  mutual: relation?.isMutual == true ? 1 : 0,
                                  onFollowersTap: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.followers,
                                    arguments: profile.id,
                                  ),
                                  onFollowingTap: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.following,
                                    arguments: profile.id,
                                  ),
                                  onMutualTap: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.mutualFollowers,
                                    arguments: profile.id,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildSection('Top Tracks', profile.uploadedTracks),
                                const SizedBox(height: 14),
                                _buildSection('Playlists', profile.playlists),
                                const SizedBox(height: 14),
                                _buildSection('Favorite Genres', profile.favoriteGenres),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildCover(String coverUrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gradientStart.withValues(alpha: 0.85),
            AppColors.background,
          ],
        ),
      ),
      child: coverUrl.isNotEmpty
          ? Opacity(
              opacity: 0.55,
              child: Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            )
          : null,
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

    return Row(
      mainAxisSize: MainAxisSize.min,
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
      ],
    );
  }

  Widget _buildStatsRow({
    required int followers,
    required int following,
    required int mutual,
    required VoidCallback onFollowersTap,
    required VoidCallback onFollowingTap,
    required VoidCallback onMutualTap,
  }) {
    Widget stat(String label, int value, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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
        stat('Followers', followers, onFollowersTap),
        const SizedBox(width: 8),
        stat('Following', following, onFollowingTap),
        const SizedBox(width: 8),
        stat('Mutual', mutual, onMutualTap),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text(
            'No items yet',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '- $item',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}
