import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../widgets/track_card.dart';
import '../../player/widgets/mini_player.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchActivityFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<FeedProvider>().fetchActivityFeed(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<FeedProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.activityFeed.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }

                if (provider.error != null && provider.activityFeed.isEmpty) {
                  return Center(child: Text('Error: ${provider.error}'));
                }

                if (provider.activityFeed.isEmpty) {
                  return const Center(
                    child: Text('No activity yet. Follow some artists!'),
                  );
                }

                return ListView.builder(
                  itemCount: provider.activityFeed.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final track = provider.activityFeed[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    track.uploader?.profileImageUrl != null
                                    ? NetworkImage(
                                        track.uploader!.profileImageUrl!,
                                      )
                                    : null,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                radius: 12,
                                child: track.uploader?.profileImageUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${track.uploader?.displayName ?? 'Unknown User'} uploaded a new track',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                                playlist: provider.activityFeed,
                              );
                            },
                            onDetails: () {
                              Navigator.of(context).pushNamed(
                                RouteNames.trackDetails,
                                arguments: track,
                              );
                            },
                            onLikeToggle: () =>
                                context.read<FeedProvider>().toggleLike(track),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
