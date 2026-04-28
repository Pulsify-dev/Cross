import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../widgets/vertical_feed_item.dart';
import '../../player/screens/track_comments_screen.dart';

class FeedScreen extends StatefulWidget {
  final bool showBottomNavigationBar;

  const FeedScreen({super.key, this.showBottomNavigationBar = false});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchFeed();
      context.read<FeedProvider>().fetchDiscoveryFeed();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content
          TabBarView(
            controller: _tabController,
            children: [_buildDiscoverTab(), _buildFollowingTab()],
          ),

          // Top Navigation (Discover / Following)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _tabButton('Discover', 0),
                        _tabButton('Following', 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNavigationBar
          ? _buildBottomNavigationBar(context)
          : null,
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.grey.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        if (provider.isDiscoveryLoading && provider.discoveryFeed.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.discoveryFeed.isEmpty) {
          return const Center(
            child: Text(
              'No tracks found in discovery.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: provider.discoveryFeed.length,
          itemBuilder: (context, index) {
            final track = provider.discoveryFeed[index];
            return VerticalFeedItem(
              track: track,
              onPlay: () {
                context.read<PlayerProvider>().playTrack(
                  track,
                  playlist: provider.discoveryFeed.toList(),
                );
              },
              onDetails: () {
                Navigator.of(
                  context,
                ).pushNamed(RouteNames.trackDetails, arguments: track);
              },
              onLikeToggle: () => provider.toggleLike(track),
              onRepostToggle: () => provider.toggleRepost(track),
              onCommentTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    height: MediaQuery.of(context).size.height * 0.75,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: TrackCommentsScreen(track: track),
                  ),
                );
              },
              onFollowTap: () {
                final targetId = track.uploader?.id ?? track.artistId;
                if (targetId != null) {
                  provider.toggleFollow(targetId);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.feed.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.feed.isEmpty) {
          return const Center(
            child: Text(
              'No tracks from people you follow.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: provider.feed.length,
          itemBuilder: (context, index) {
            final item = provider.feed[index];
            return VerticalFeedItem(
              track: item.track!,
              onPlay: () {
                context.read<PlayerProvider>().playTrack(
                  item.track!,
                  playlist: provider.feed.map((e) => e.track!).toList(),
                );
              },
              onDetails: () {
                Navigator.of(
                  context,
                ).pushNamed(RouteNames.trackDetails, arguments: item.track!);
              },
              onLikeToggle: () => provider.toggleLike(item.track!),
              onRepostToggle: () => provider.toggleRepost(item.track!),
              onCommentTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    height: MediaQuery.of(context).size.height * 0.75,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: TrackCommentsScreen(track: item.track!),
                  ),
                );
              },
              onFollowTap: () {
                final targetId = item.track!.uploader?.id ?? item.track!.artistId;
                if (targetId != null) {
                  provider.toggleFollow(targetId);
                }
              },
            );
          },
        );
      },
    );
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
                Navigator.of(
                  context,
                ).pushReplacementNamed(RouteNames.mainScreen, arguments: 0);
              },
            ),
            _navItem(
              icon: Icons.search,
              label: 'Search',
              onTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(RouteNames.mainScreen, arguments: 1);
              },
            ),
            _navItem(
              icon: Icons.library_music,
              label: 'Library',
              onTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(RouteNames.mainScreen, arguments: 2);
              },
            ),
            _navItem(
              icon: Icons.dynamic_feed,
              label: 'Feed',
              onTap: () {
                context.read<FeedProvider>().fetchFeed();
              },
            ),
            _navItem(
              icon: Icons.workspace_premium,
              label: 'Upgrade',
              onTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(RouteNames.mainScreen, arguments: 4);
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
}
