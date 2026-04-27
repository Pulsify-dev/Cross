import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/profile/models/profile_data.dart';
import 'package:cross/providers/auth_provider.dart';
import 'package:cross/providers/profile_provider.dart';
import 'package:cross/providers/social_provider.dart';
import 'package:cross/providers/upload_provider.dart';
import 'package:cross/routes/route_names.dart';
import 'package:cross/features/upload/models/upload_model.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  AuthProvider? _authProviderListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authProviderListener = context.read<AuthProvider>();
      _authProviderListener!.addListener(_onAuthUserChanged);
      _loadUploadedTracksForCurrentArtist();
      _loadProfile();
      _loadSocialStats();
    });
  }

  @override
  void dispose() {
    _authProviderListener?.removeListener(_onAuthUserChanged);
    super.dispose();
  }

  void _onAuthUserChanged() {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null && !authProvider.isLoading) {
      final uploadProvider = context.read<UploadProvider>();
      if (uploadProvider.errorMessage != null && uploadProvider.allUploadedTracks.isEmpty) {
        _loadUploadedTracksForCurrentArtist();
      }
    }
  }

  Future<void> _loadProfile() async {
    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.loadMyProfile();
  }

  Future<void> _loadUploadedTracksForCurrentArtist() async {
    final authProvider = context.read<AuthProvider>();
    final uploadProvider = context.read<UploadProvider>();

    final currentArtistId = authProvider.currentUser?.id;

    await uploadProvider.loadCurrentArtistTracks(
      currentArtistId: currentArtistId,
      page: 1,
      limit: 20,
      replace: true,
    );
  }

  Future<void> _loadSocialStats() async {
    final socialProvider = context.read<SocialProvider>();
    final userId = socialProvider.currentUserId;
    await socialProvider.loadFollowers(userId);
    await socialProvider.loadFollowing(userId);
  }

  static const _playlistItems = <Map<String, String>>[];
  static const _recentItems = <Map<String, String>>[];
  static const _favoriteGenres = <Map<String, String>>[];

  Future<void> _handleProfileMenuSelection(String value) async {
    if (value == 'suggested_users') {
      Navigator.pushNamed(context, RouteNames.suggestedUsers);
      return;
    }

    if (value == 'blocked_users') {
      Navigator.pushNamed(context, RouteNames.blockedUsers);
    }
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final profile = profileProvider.profile;
        final isLoading = profileProvider.isLoading;
        final errorMessage = profileProvider.errorMessage;

        if (isLoading && profile == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (errorMessage != null && profile == null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loadProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (profile == null) {
          return const Scaffold(
            body: Center(
              child: Text('No profile data available'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            centerTitle: true,
            title: const Text('Profile'),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert),
                onSelected: _handleProfileMenuSelection,
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'suggested_users',
                    child: Row(
                      children: [
                        Icon(Icons.person_search, size: 20),
                        SizedBox(width: 8),
                        Text('Suggested Users'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'blocked_users',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 20),
                        SizedBox(width: 8),
                        Text('Blocked Users'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: DefaultTabController(
            length: 4,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileHeader(context, profile),
                        const SizedBox(height: 16),
                        _buildStatsRow(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarHeader(
                      tabBar: TabBar(
                        indicatorColor: AppColors.primary,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'Uploaded'),
                          Tab(text: 'Playlists'),
                          Tab(text: 'Recent'),
                          Tab(text: 'Favorite Genre'),
                        ],
                      ),
                      backgroundColor: theme.scaffoldBackgroundColor,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildUploadedTrackList(context),
                  _buildTrackList(context, _playlistItems, 'No playlists yet.'),
                  _buildTrackList(context, _recentItems, 'No recent tracks.'),
                  _buildTrackList(context, _favoriteGenres, 'No favorite genres yet.'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, ProfileData profile) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarSize = screenWidth.clamp(96.0, 140.0) * 0.9;
    final borderSize = avatarSize * 0.04;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: borderSize,
                  ),
                ),
                child: ClipOval(
                  child: Image(
                    image: avatarImage(
                      path: profile.avatarPath,
                      bytes: profile.avatarBytes,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceElevated,
                      child: Center(
                        child: Icon(
                          Icons.person,
                          size: avatarSize * 0.45,
                          color: AppColors.iconMuted.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: avatarSize * 0.28,
                height: avatarSize * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: borderSize,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.verified, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName?.isNotEmpty == true
                ? profile.displayName!
                : profile.username,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (profile.bio.isNotEmpty) ...[
            Text(
              profile.bio,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (profile.location != null && profile.location!.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  profile.location!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('profile_edit_button'),
                  onPressed: () {
                    Navigator.pushNamed(context, RouteNames.editProfile)
                        .then((_) => _loadProfile());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('profile_logout_button'),
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.logout, size: 20, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final theme = Theme.of(context);

    Widget statItem(String value, String label, {VoidCallback? onTap, Key? itemKey}) {
      return Flexible(
        fit: FlexFit.tight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: itemKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
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
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Consumer2<SocialProvider, UploadProvider>(
      builder: (context, socialProvider, uploadProvider, _) {
        final followersCount = socialProvider.listTotal(SocialListType.followers);
        final followingCount = socialProvider.listTotal(SocialListType.following);
        final tracksCount = uploadProvider.allUploadedTracks.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 370;

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    statItem(
                      '$followersCount',
                      'Followers',
                      onTap: () => Navigator.pushNamed(context, RouteNames.followers),
                      itemKey: const Key('profile_followers_stat'),
                    ),
                    const SizedBox(height: 12),
                    statItem(
                      '$followingCount',
                      'Following',
                      onTap: () => Navigator.pushNamed(context, RouteNames.following),
                      itemKey: const Key('profile_following_stat'),
                    ),
                    const SizedBox(height: 12),
                    statItem('$tracksCount', 'Tracks'),
                  ],
                );
              }

              return Row(
                children: [
                  statItem(
                    '$followersCount',
                    'Followers',
                    onTap: () => Navigator.pushNamed(context, RouteNames.followers),
                    itemKey: const Key('profile_followers_stat'),
                  ),
                  const SizedBox(width: 12),
                  statItem(
                    '$followingCount',
                    'Following',
                    onTap: () => Navigator.pushNamed(context, RouteNames.following),
                    itemKey: const Key('profile_following_stat'),
                  ),
                  const SizedBox(width: 12),
                  statItem('$tracksCount', 'Tracks'),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTrackList(
    BuildContext context,
    List<Map<String, String>> trackItems,
    String emptyMessage,
  ) {
    if (trackItems.isEmpty) {
      return Center(
        child: Text(emptyMessage),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: trackItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final track = trackItems[index];
        return _buildTrackItem(
          imageUrl: track['image']!,
          title: track['title']!,
          subtitle: track['subtitle']!,
          plays: track['plays']!,
        );
      },
    );
  }

  Widget _buildUploadedTrackList(BuildContext context) {
    return Consumer<UploadProvider>(
      builder: (context, uploadProvider, _) {
        final tracks = uploadProvider.allUploadedTracks;

        if (uploadProvider.isLoading &&
            uploadProvider.currentOperation == 'loadArtistTracks' &&
            tracks.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (uploadProvider.errorMessage != null && tracks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    uploadProvider.errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loadUploadedTracksForCurrentArtist,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (tracks.isEmpty) {
          return const Center(
            child: Text('No uploaded tracks yet.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: tracks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final track = tracks[index];
            return _buildTrackItem(
              imageUrl: track.artworkPathOrUrl,
              title: track.title,
              subtitle: track.genre,
              plays: '0 plays',
              imageBytes: track.artworkBytes,
              onMorePressed: () => _showUploadedTrackActions(track),
            );
          },
        );
      },
    );
  }

  Future<void> _showUploadedTrackActions(UploadModel track) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'edit') {
      Navigator.pushNamed(
        context,
        RouteNames.editUploadedTrack,
        arguments: track.id,
      );
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete Track'),
            content: const Text(
              'Are you sure you want to delete this track? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmed == true && mounted) {
        final uploadProvider = context.read<UploadProvider>();
        final deleted = await uploadProvider.deleteTrackById(track.id);
        if (!mounted) return;

        if (!deleted) {
          final errorText =
              uploadProvider.errorMessage ?? 'Failed to delete track.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorText)),
          );
          uploadProvider.clearError();
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uploadProvider.successMessage ?? 'Track deleted successfully.',
            ),
          ),
        );
        uploadProvider.clearSuccessMessage();
      }
    }
  }

  Widget _buildTrackItem({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String plays,
    Uint8List? imageBytes,
    VoidCallback? onMorePressed,
  }) {
    final theme = Theme.of(context);
    final imageSize = math.min(64.0, MediaQuery.of(context).size.width * 0.16);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(
                image: imageBytes != null
                    ? MemoryImage(imageBytes)
                    : NetworkImage(imageUrl) as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plays,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: onMorePressed,
                icon: const Icon(
                  Icons.more_horiz,
                  color: AppColors.iconSecondary,
                ),
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
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
