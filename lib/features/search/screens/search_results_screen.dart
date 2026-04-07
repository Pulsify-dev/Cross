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
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.searchResults.isEmpty) {
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
            itemCount: provider.searchResults.length,
            itemBuilder: (context, index) {
              final track = provider.searchResults[index];
              return TrackTile(
                track: track,
                onPlay: () {
                  context.read<PlayerProvider>().playTrack(
                    track,
                    playlist: provider.searchResults,
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
    );
  }
}
