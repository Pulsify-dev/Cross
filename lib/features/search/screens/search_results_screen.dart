import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../../feed/widgets/track_tile.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Results for "$query"')),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (searchProvider.searchResults.isEmpty) {
            return Center(
              child: Text(
                'No tracks found.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: searchProvider.searchResults.length,
            itemBuilder: (context, index) {
              final track = searchProvider.searchResults[index];

              return TrackTile(
                track: track,
                showLike: true,
                onPlay: () {
                  context.read<PlayerProvider>().playTrack(
                    track,
                    playlist: searchProvider.searchResults,
                  );
                },
                onDetails: () {
                  context.read<FeedProvider>().cleanupUnlikedTracks();
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
    );
  }
}
