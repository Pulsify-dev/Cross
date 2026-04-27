import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import 'track_tile.dart';

class ListeningHistoryWidget extends StatefulWidget {
  const ListeningHistoryWidget({super.key});

  @override
  State<ListeningHistoryWidget> createState() => _ListeningHistoryWidgetState();
}
class _ListeningHistoryWidgetState extends State<ListeningHistoryWidget> {
  String? _lastTrackId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feed = context.read<FeedProvider>();
      if (feed.recentlyPlayed.isEmpty) {
        feed.fetchRecentlyPlayed();
      }
      
      // Listen to player changes to refresh recently played
      final player = context.read<PlayerProvider>();
      _lastTrackId = player.currentTrack?.id;
      player.addListener(_onPlayerChanged);
    });
  }

  @override
  void dispose() {
    // Note: We need a reference to player that doesn't depend on context if we want to dispose safely,
    // but in this case, the provider is likely still alive. 
    // However, it's safer to get the provider in initState and store it.
    super.dispose();
  }

  void _onPlayerChanged() {
    if (!mounted) return;
    final player = context.read<PlayerProvider>();
    final currentId = player.currentTrack?.id;
    final isCompleted = player.processingState == ProcessingState.completed;
    
    if ((currentId != _lastTrackId && currentId != null) || isCompleted) {
      _lastTrackId = currentId;
      // Delay slightly to give backend time to process the recordPlay call
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.read<FeedProvider>().fetchRecentlyPlayed();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, child) {
        if (feedProvider.isHistoryLoading && feedProvider.recentlyPlayed.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (feedProvider.recentlyPlayed.isEmpty) {
          return const SizedBox.shrink();
        }

        final recentTracks = feedProvider.recentlyPlayed.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Played',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.history);
                    },
                    child: Text(
                      'Show More',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTracks.length,
              itemBuilder: (context, index) {
                final track = recentTracks[index];
                return TrackTile(
                  track: track,
                  onPlay: () {
                    context.read<PlayerProvider>().playTrack(
                          track,
                          playlist: feedProvider.recentlyPlayed,
                        );
                  },
                  onDetails: () {
                    context.read<FeedProvider>().cleanupUnlikedTracks();
                    Navigator.of(context).pushNamed(
                      RouteNames.trackDetails,
                      arguments: track,
                    );
                  },
                  onLikeToggle: () => context.read<FeedProvider>().toggleLike(track),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
