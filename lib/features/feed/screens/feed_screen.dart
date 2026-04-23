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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchFeed();
      context.read<FeedProvider>().fetchTrendingTracks();
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'Following'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabController.index == 0) {
                context.read<FeedProvider>().fetchTrendingTracks();
              } else {
                context.read<FeedProvider>().fetchFeed();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildDiscoverTab(), _buildFollowingTab()],
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

  Widget _buildDiscoverTab() {
    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        if (provider.isTrendingLoading && provider.trendingTracks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.trendingTracks.isEmpty) {
          return Center(child: Text('Error: ${provider.error}'));
        }

        if (provider.trendingTracks.isEmpty) {
          return const Center(child: Text('No trending tracks found.'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchTrendingTracks(),
          child: ListView.builder(
            itemCount: provider.trendingTracks.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final track = provider.trendingTracks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: TrackCard(
                  track: track,
                  onPlay: () {
                    context.read<PlayerProvider>().playTrack(
                      track,
                      playlist: provider.trendingTracks,
                    );
                  },
                  onDetails: () {
                    Navigator.of(
                      context,
                    ).pushNamed(RouteNames.trackDetails, arguments: track);
                  },
                  onLikeToggle: () => provider.toggleLike(track),
                ),
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

        if (provider.error != null && provider.feed.isEmpty) {
          return Center(child: Text('Error: ${provider.error}'));
        }

        if (provider.feed.isEmpty) {
          return const Center(child: Text('No tracks from people you follow.'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchFeed(),
          child: ListView.builder(
            itemCount: provider.feed.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final track = provider.feed[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: TrackCard(
                  track: track,
                  onPlay: () {
                    context.read<PlayerProvider>().playTrack(
                      track,
                      playlist: provider.feed,
                    );
                  },
                  onDetails: () {
                    Navigator.of(
                      context,
                    ).pushNamed(RouteNames.trackDetails, arguments: track);
                  },
                  onLikeToggle: () => provider.toggleLike(track),
                ),
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
