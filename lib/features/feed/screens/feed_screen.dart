import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  final PageController _discoverPageController = PageController();
  final PageController _followingPageController = PageController();
  PlayerProvider? _playerProvider;

  // Track the currently active page index per tab
  int _discoverActiveIndex = 0;
  int _followingActiveIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
        // When switching tabs, play the active track from the new tab
        _onTabChanged(_tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchFeed();
      context.read<FeedProvider>().fetchDiscoveryFeed();
      _playerProvider = context.read<PlayerProvider>();
      _playerProvider?.addListener(_onPlayerStateChanged);
    });
  }

  @override
  void dispose() {
    _playerProvider?.removeListener(_onPlayerStateChanged);
    _tabController.dispose();
    _discoverPageController.dispose();
    _followingPageController.dispose();
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final player = _playerProvider;
    if (player == null) return;
    final track = player.currentTrack;
    if (track == null) return;

    if (_tabController.index == 0) {
      final provider = context.read<FeedProvider>();
      final newIndex = provider.discoveryFeed.indexWhere(
        (t) => t.id == track.id,
      );
      if (newIndex != -1 && newIndex != _discoverActiveIndex) {
        if (_discoverPageController.hasClients) {
          _discoverPageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    } else {
      final provider = context.read<FeedProvider>();
      final newIndex = provider.feed.indexWhere(
        (item) => item.track?.id == track.id,
      );
      if (newIndex != -1 && newIndex != _followingActiveIndex) {
        if (_followingPageController.hasClients) {
          _followingPageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  void _onTabChanged(int tabIndex) {
    if (tabIndex == 0) {
      // Switched to Discover → play active discover track
      _autoPlayDiscoverTrack(_discoverActiveIndex);
    } else {
      // Switched to Following → play active following track
      _autoPlayFollowingTrack(_followingActiveIndex);
    }
  }

  void _autoPlayDiscoverTrack(int index) {
    setState(() => _discoverActiveIndex = index);
    final provider = context.read<FeedProvider>();
    if (provider.discoveryFeed.isEmpty) return;
    if (index < 0 || index >= provider.discoveryFeed.length) return;

    final track = provider.discoveryFeed[index];
    final player = context.read<PlayerProvider>();

    // Don't re-trigger if already playing this track
    if (player.currentTrack?.id == track.id && player.isPlaying) return;

    player.playTrack(track, playlist: provider.discoveryFeed.toList());
    player.setRepeatOne(true);
  }

  void _autoPlayFollowingTrack(int index) {
    setState(() => _followingActiveIndex = index);
    final provider = context.read<FeedProvider>();
    if (provider.feed.isEmpty) return;
    if (index < 0 || index >= provider.feed.length) return;

    final item = provider.feed[index];
    if (item.track == null) return;

    final player = context.read<PlayerProvider>();

    // Don't re-trigger if already playing this track
    if (player.currentTrack?.id == item.track!.id && player.isPlaying) return;

    player.playTrack(
      item.track!,
      playlist: provider.feed.map((e) => e.track!).toList(),
    );
    player.setRepeatOne(true);
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
            physics: const NeverScrollableScrollPhysics(),
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

        return Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              if (pointerSignal.scrollDelta.dy > 0) {
                _discoverPageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              } else if (pointerSignal.scrollDelta.dy < 0) {
                _discoverPageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              }
            }
          },
          child: PageView.builder(
            controller: _discoverPageController,
          scrollDirection: Axis.vertical,
          itemCount: provider.discoveryFeed.length,
          onPageChanged: _autoPlayDiscoverTrack,
          itemBuilder: (context, index) {
            final track = provider.discoveryFeed[index];
            return VerticalFeedItem(
              track: track,
              isActive: index == _discoverActiveIndex,
              onPlay: () {
                final player = context.read<PlayerProvider>();
                player.playTrack(
                  track,
                  playlist: provider.discoveryFeed.toList(),
                );
                player.setRepeatOne(true);
              },
              onDetails: () {
                Navigator.of(
                  context,
                ).pushNamed(RouteNames.trackDetails, arguments: {
                  'track': track,
                  'playlist': provider.discoveryFeed.toList(),
                });
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
        ),
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

        return Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              if (pointerSignal.scrollDelta.dy > 0) {
                _followingPageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              } else if (pointerSignal.scrollDelta.dy < 0) {
                _followingPageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              }
            }
          },
          child: PageView.builder(
            controller: _followingPageController,
          scrollDirection: Axis.vertical,
          itemCount: provider.feed.length,
          onPageChanged: _autoPlayFollowingTrack,
          itemBuilder: (context, index) {
            final item = provider.feed[index];
            return VerticalFeedItem(
              track: item.track!,
              isActive: index == _followingActiveIndex,
              onPlay: () {
                final player = context.read<PlayerProvider>();
                player.playTrack(
                  item.track!,
                  playlist: provider.feed.map((e) => e.track!).toList(),
                );
                player.setRepeatOne(true);
              },
              onDetails: () {
                Navigator.of(
                  context,
                ).pushNamed(RouteNames.trackDetails, arguments: {
                  'track': item.track!,
                  'playlist': provider.feed.map((e) => e.track!).toList(),
                });
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
                final targetId =
                    item.track!.uploader?.id ?? item.track!.artistId;
                if (targetId != null) {
                  provider.toggleFollow(targetId);
                }
              },
            );
          },
        ),
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
