import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/profile/models/profile_data.dart';
import 'package:cross/providers/auth_provider.dart';
import 'package:cross/providers/profile_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadUploadedTracksForCurrentArtist();
    });
  }

  Future<void> _loadUploadedTracksForCurrentArtist() async {
    final authProvider = context.read<AuthProvider>();
    final uploadProvider = context.read<UploadProvider>();

    // TODO(profile/auth/session): Source this id from the fully integrated
    // current user/profile/session pipeline once that flow is completed.
    final currentArtistId = authProvider.currentUser?.id;

    await uploadProvider.loadCurrentArtistTracks(
      currentArtistId: currentArtistId,
      page: 1,
      limit: 20,
      replace: true,
    );
  }

  static const _playlistItems = [
    {
      'title': 'Late Night Vibes',
      'subtitle': 'Playlist • 12 songs',
      'plays': '156K plays',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCKlgPSzOBWDjf6m-ENOfVNJ7d84EuEkszfYCt69BgIheo1VIvde6YIYsfQTfANtBpnsu_4Zb1J8r4nw481yUii9RuFVRpYMwC1f3SrPpw1eBo2nOFBRLO8ojpzhc6PFr2miNPvYHjqoXc3cjGfTdHfkN4C9aPClk3Ph0JIBotryBxBIdEwKNvJfRwabbz_UOTNr6r9naWNsXu2iTCtzGY8FwZWo6298hCrS-zMIlfbwiYYo5NvIn4gyLwXpDcu5Mbqh_4POQo7l4Y',
    },
    {
      'title': 'Study Sessions',
      'subtitle': 'Playlist • 24 songs',
      'plays': '2.3M plays',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCV0zNT-Fr8pb_LW_sA2QdcVBZF2ndTEWzK-zaDfJ55TtQbXdhvnBL-fUEaONTf19lxXLdxWNSqOZTnXGtV0YUrzQhYrzEeae3bz8DC1hjcOYmg2u6MpDGbjxtQy0Dwqtxe--EBLyFFVzvbOyTUKCcbipRZVXLbFYXsLTKLQ0v1dWmJicfQlUn-r7txUEqyYazEbJnomXs6gSIPM5ov0I9QJyJBQozZEEbp1u8nos9hMQkcJ6ZP9c9p_7Xt20BYdx2emy1Kaq8e5Dg',
    },
    {
      'title': 'Chill Beats',
      'subtitle': 'Playlist • 18 songs',
      'plays': '567K plays',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBwwb6cioW2l3ZGQ7Daxm2tLZNacCZ7QLjy8X0izIozKkcHVHHv65frBFBIl7JQ2d6htyh2vc2pC2yov4aohqVrJWRCdT0RR8OhbDAMxosiIxmd2rnFZVTUtdk-U93vzSDApK3QJp9yIN3_-2XRfZZ2kofYzNdnaKkf__si-9H5B3FKttgr1TdoLUElOHIw07hjNP12YFDHEPbqRegvfm1hygD-QVBH8xbSF8I75OQoTR_tDIQPViJ7Ybj7oUSrUmG8W39piQ5vAWQ',
    },
  ];

  static const _recentItems = [
    {
      'title': 'Spring Blossom',
      'subtitle': 'Indie Pop • 3:15',
      'plays': '540K plays',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAWROw6qxsbQJKACyZZ65DEI88V-J9kbSie21JamMJzojoRrttVgcXrOXi-5BIwAR9r8xwDKDlzmP9WLUV82-2IrYKiqt9p7Ri2e0GXS5IUTseWESRPBLxNHqQKV8vs26l8X27SRpllBK8oAnNRVZRY0wybQwOVgGGD3p8o_3CPG6lIjAQpFMlNuzNpd_1-cpgCm-HtQy7UXqbaPB41iaPpWCQnCK-u5x9L3mGiGohzs7gPCX-XUUytvkERvMWhzO1c1J-T-xmoEgg',
    },
    {
      'title': 'Urban Dreams',
      'subtitle': 'Hip-Hop • 4:02',
      'plays': '1.8M plays',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCKlgPSzOBWDjf6m-ENOfVNJ7d84EuEkszfYCt69BgIheo1VIvde6YIYsfQTfANtBpnsu_4Zb1J8r4nw481yUii9RuFVRpYMwC1f3SrPpw1eBo2nOFBRLO8ojpzhc6PFr2miNPvYHjqoXc3cjGfTdHfkN4C9aPClk3Ph0JIBotryBxBIdEwKNvJfRwabbz_UOTNr6r9naWNsXu2iTCtzGY8FwZWo6298hCrS-zMIlfbwiYYo5NvIn4gyLwXpDcu5Mbqh_4POQo7l4Y',
    },
    {
      'title': 'Ocean Waves',
      'subtitle': 'Chillwave • 4:45',
      'plays': '392K plays',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCV0zNT-Fr8pb_LW_sA2QdcVBZF2ndTEWzK-zaDfJ55TtQbXdhvnBL-fUEaONTf19lxXLdxWNSqOZTnXGtV0YUrzQhYrzEeae3bz8DC1hjcOYmg2u6MpDGbjxtQy0Dwqtxe--EBLyFFVzvbOyTUKCcbipRZVXLbFYXsLTKLQ0v1dWmJicfQlUn-r7txUEqyYazEbJnomXs6gSIPM5ov0I9QJyJBQozZEEbp1u8nos9hMQkcJ6ZP9c9p_7Xt20BYdx2emy1Kaq8e5Dg',
    },
    {
      'title': 'Neon Sunset Vibes',
      'subtitle': 'Electronic • 3:45',
      'plays': '2.1M plays',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBwwb6cioW2l3ZGQ7Daxm2tLZNacCZ7QLjy8X0izIozKkcHVHHv65frBFBIl7JQ2d6htyh2vc2pC2yov4aohqVrJWRCdT0RR8OhbDAMxosiIxmd2rnFZVTUtdk-U93vzSDApK3QJp9yIN3_-2XRfZZ2kofYzNdnaKkf__si-9H5B3FKttgr1TdoLUElOHIw07hjNP12YFDHEPbqRegvfm1hygD-QVBH8xbSF8I75OQoTR_tDIQPViJ7Ybj7oUSrUmG8W39piQ5vAWQ',
    },
  ];

  Future<void> _handleProfileMenuSelection(String value) async {
    if (value != 'logout') {
      return;
    }

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

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: const Text('Profile'),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert),
                onSelected: _handleProfileMenuSelection,
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Log out'),
                  ),
                ],
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileHeader(context, profile),
                        const SizedBox(height: 16),
                        _buildStatsRow(context, profile),
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
                  _buildTrackList(context, _playlistItems),
                  _buildTrackList(context, _recentItems),
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
            profile.username,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.bio,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.editProfile);
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
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, ProfileData profile) {
    final theme = Theme.of(context);

    Widget statItem(String value, String label, {VoidCallback? onTap}) {
      return Flexible(
        fit: FlexFit.tight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
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
                  '12.4K',
                  'Followers',
                  onTap: () =>
                      Navigator.pushNamed(context, RouteNames.followers),
                ),
                const SizedBox(height: 12),
                statItem(
                  '450',
                  'Following',
                  onTap: () =>
                      Navigator.pushNamed(context, RouteNames.following),
                ),
                const SizedBox(height: 12),
                statItem('86', 'Tracks'),
              ],
            );
          }

          return Row(
            children: [
              statItem(
                '12.4K',
                'Followers',
                onTap: () => Navigator.pushNamed(context, RouteNames.followers),
              ),
              const SizedBox(height: 12),
              statItem(
                '450',
                'Following',
                onTap: () => Navigator.pushNamed(context, RouteNames.following),
              ),
              const SizedBox(height: 12),
              statItem('86', 'Tracks'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrackList(
    BuildContext context,
    List<Map<String, String>> trackItems,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: trackItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
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
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final track = tracks[index];
            return _buildTrackItem(
              imageUrl: track.artworkPathOrUrl,
              title: track.title,
              subtitle: '${track.genre} • ${track.status.name}',
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
