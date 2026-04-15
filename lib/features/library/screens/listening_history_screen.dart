import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../../../features/feed/widgets/track_tile.dart';

import '../../../features/player/widgets/mini_player.dart';


class ListeningHistoryScreen extends StatefulWidget {
  const ListeningHistoryScreen({super.key});

  @override
  State<ListeningHistoryScreen> createState() => _ListeningHistoryScreenState();
}

class _ListeningHistoryScreenState extends State<ListeningHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchListeningHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listening History')),
      body: Column(
        children: [
          Expanded(
            child: Consumer<FeedProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.listeningHistory.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.listeningHistory.isEmpty) {
                  return const Center(
                    child: Text('No history yet. Start listening!'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.listeningHistory.length,
                  itemBuilder: (context, index) {
                    final track = provider.listeningHistory[index];
                    return TrackTile(
                      track: track,
                      onPlay: () {
                        context.read<PlayerProvider>().playTrack(
                          track,
                          playlist: provider.listeningHistory,
                        );
                      },
                      onDetails: () {
                        Navigator.of(
                          context,
                        ).pushNamed(RouteNames.trackDetails, arguments: track);
                      },
                      onLikeToggle: () =>
                          context.read<FeedProvider>().toggleLike(track),
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
