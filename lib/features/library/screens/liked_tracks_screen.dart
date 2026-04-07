import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../../feed/widgets/track_tile.dart';
import '../../player/widgets/mini_player.dart';

class LikedTracksScreen extends StatefulWidget {
  const LikedTracksScreen({super.key});

  @override
  State<LikedTracksScreen> createState() => _LikedTracksScreenState();
}

class _LikedTracksScreenState extends State<LikedTracksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchLikedTracks();
    });
  }

  @override
  void dispose() {
    context.read<FeedProvider>().cleanupUnlikedTracks();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<FeedProvider>().cleanupUnlikedTracks();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Liked Tracks')),
        body: Column(
          children: [
            Expanded(
              child: Consumer<FeedProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.likedTracks.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.likedTracks.isEmpty) {
                    return const Center(child: Text('No liked tracks yet'));
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchLikedTracks(),
                    child: ListView.builder(
                      itemCount: provider.likedTracks.length,
                      itemBuilder: (context, index) {
                        final track = provider.likedTracks[index];
                        return TrackTile(
                          track: track,
                          onPlay: () {
                            context.read<FeedProvider>().cleanupUnlikedTracks();
                            context.read<PlayerProvider>().playTrack(
                              track,
                              playlist: provider.likedTracks,
                            );
                          },
                          onDetails: () {
                            context.read<FeedProvider>().cleanupUnlikedTracks();
                            Navigator.of(context).pushNamed(
                              RouteNames.trackDetails,
                              arguments: track,
                            );
                          },
                          onLikeToggle: () =>
                              context.read<FeedProvider>().toggleLike(track),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }
}
