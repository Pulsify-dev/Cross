import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/profile/models/profile_data.dart';
import 'package:cross/providers/profile_provider.dart';
import 'package:cross/routes/route_names.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _selectedBottomNav = 4;

  static const _trackItems = [
    {
      'title': 'Neon Sunset Vibes',
      'subtitle': 'Electronic • 3:45',
      'plays': '2.1M plays',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCKlgPSzOBWDjf6m-ENOfVNJ7d84EuEkszfYCt69BgIheo1VIvde6YIYsfQTfANtBpnsu_4Zb1J8r4nw481yUii9RuFVRpYMwC1f3SrPpw1eBo2nOFBRLO8ojpzhc6PFr2miNPvYHjqoXc3cjGfTdHfkN4C9aPClk3Ph0JIBotryBxBIdEwKNvJfRwabbz_UOTNr6r9naWNsXu2iTCtzGY8FwZWo6298hCrS-zMIlfbwiYYo5NvIn4gyLwXpDcu5Mbqh_4POQo7l4Y',
    },
    {
      'title': 'Midnight Echoes',
      'subtitle': 'Ambient • 5:12',
      'plays': '850K plays',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCV0zNT-Fr8pb_LW_sA2QdcVBZF2ndTEWzK-zaDfJ55TtQbXdhvnBL-fUEaONTf19lxXLdxWNSqOZTnXGtV0YUrzQhYrzEeae3bz8DC1hjcOYmg2u6MpDGbjxtQy0Dwqtxe--EBLyFFVzvbOyTUKCcbipRZVXLbFYXsLTKLQ0v1dWmJicfQlUn-r7txUEqyYazEbJnomXs6gSIPM5ov0I9QJyJBQozZEEbp1u8nos9hMQkcJ6ZP9c9p_7Xt20BYdx2emy1Kaq8e5Dg',
    },
    {
      'title': 'Pacific Drift',
      'subtitle': 'Lo-fi • 2:58',
      'plays': '1.4M plays',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBwwb6cioW2l3ZGQ7Daxm2tLZNacCZ7QLjy8X0izIozKkcHVHHv65frBFBIl7JQ2d6htyh2vc2pC2yov4aohqVrJWRCdT0RR8OhbDAMxosiIxmd2rnFZVTUtdk-U93vzSDApK3QJp9yIN3_-2XRfZZ2kofYzNdnaKkf__si-9H5B3FKttgr1TdoLUElOHIw07hjNP12YFDHEPbqRegvfm1hygD-QVBH8xbSF8I75OQoTR_tDIQPViJ7Ybj7oUSrUmG8W39piQ5vAWQ',
    },
    {
      'title': 'City Lights',
      'subtitle': 'Chill Hop • 3:20',
      'plays': '920K plays',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAWROw6qxsbQJKACyZZ65DEI88V-J9kbSie21JamMJzojoRrttVgcXrOXi-5BIwAR9r8xwDKDlzmP9WLUV82-2IrYKiqt9p7Ri2e0GXS5IUTseWESRPBLxNHqQKV8vs26l8X27SRpllBK8oAnNRVZRY0wybQwOVgGGD3p8o_3CPG6lIjAQpFMlNuzNpd_1-cpgCm-HtQy7UXqbaPB41iaPpWCQnCK-u5x9L3mGiGohzs7gPCX-XUUytvkERvMWhzO1c1J-T-xmoEgg',
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final profile = profileProvider.profile;
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Profile'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {},
              tooltip: 'Back',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
                tooltip: 'More',
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
                  _buildTrackList(context, _trackItems),
                  _buildTrackList(context, _playlistItems),
                  _buildTrackList(context, _recentItems),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(context),
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
                  border: Border.all(color: AppColors.primary, width: borderSize),
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
                  child: Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 18,
                  ),
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

    Widget statItem(String value, String label) {
      return Flexible(
        fit: FlexFit.tight,
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
                statItem('12.4K', 'Followers'),
                const SizedBox(height: 12),
                statItem('450', 'Following'),
                const SizedBox(height: 12),
                statItem('86', 'Tracks'),
              ],
            );
          }

          return Row(
            children: [
              statItem('12.4K', 'Followers'),
              const SizedBox(width: 12),
              statItem('450', 'Following'),
              const SizedBox(width: 12),
              statItem('86', 'Tracks'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrackList(BuildContext context, List<Map<String, String>> trackItems) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
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

  Widget _buildTrackItem({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String plays,
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
                image: NetworkImage(imageUrl),
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
                onPressed: () {},
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

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBarBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 16, left: 12, right: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _bottomNavItem(
              icon: Icons.home,
              label: 'Home',
              index: 0,
              selected: _selectedBottomNav == 0,
            ),
            _bottomNavItem(
              icon: Icons.search,
              label: 'Search',
              index: 1,
              selected: _selectedBottomNav == 1,
            ),
            _bottomNavItem(
              icon: Icons.library_music,
              label: 'Playlists',
              index: 2,
              selected: _selectedBottomNav == 2,
            ),
            _bottomNavItem(
              icon: Icons.chat_bubble,
              label: 'Messages',
              index: 3,
              selected: _selectedBottomNav == 3,
              showBadge: true,
            ),
            _bottomNavItem(
              icon: Icons.person,
              label: 'Profile',
              index: 4,
              selected: _selectedBottomNav == 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool selected,
    bool showBadge = false,
  }) {
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _selectedBottomNav = index;
      }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 24),
              if (showBadge)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeader oldDelegate) {
    return oldDelegate.tabBar != tabBar || oldDelegate.backgroundColor != backgroundColor;
  }
}