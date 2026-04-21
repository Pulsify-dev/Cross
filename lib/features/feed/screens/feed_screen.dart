import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../widgets/track_card.dart';
import '../../player/widgets/mini_player.dart';
import '../models/track.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchActivityFeed();
      context.read<FeedProvider>().fetchTrendingTracks();
    });
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Activity Feed'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'For You'),
              Tab(text: 'Following'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<FeedProvider>().fetchActivityFeed();
                context.read<FeedProvider>().fetchTrendingTracks();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<FeedProvider>(
                builder: (context, provider, child) {
                  return TabBarView(
                    children: [
                      // For You Tab
                      _buildTrackList(
                        context,
                        provider,
                        provider.trendingTracks,
                        'No recommendations yet. Listen to more tracks!',
                        provider.isTrendingLoading,
                      ),
                      // Following Tab
                      _buildTrackList(
                        context,
                        provider,
                        provider.activityFeed,
                        'No activity yet. Follow some artists!',
                        provider.isLoading,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
