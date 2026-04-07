import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  @override
  void initState() {
    super.initState();
    // Fetch history if empty whenever this widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feed = context.read<FeedProvider>();
      if (feed.listeningHistory.isEmpty) {
        feed.fetchListeningHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, child) {
        if (feedProvider.isLoading && feedProvider.listeningHistory.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (feedProvider.listeningHistory.isEmpty) {
          return const SizedBox.shrink(); // Don't show anything if history is empty
        }

        final recentTracks = feedProvider.listeningHistory.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Listening History',
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
                  showLike: true,
                  onPlay: () {
                    context.read<PlayerProvider>().playTrack(
                          track,
                          playlist: feedProvider.listeningHistory,
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
