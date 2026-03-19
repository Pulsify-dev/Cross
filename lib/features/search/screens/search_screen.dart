import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/player_provider.dart';
import '../../feed/widgets/track_tile.dart';
import '../../player/screens/track_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Search for tracks or artists',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            context.read<SearchProvider>().search(value);
          },
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (context, search, child) {
          if (search.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = search.searchResults;

          if (results.isEmpty && _searchController.text.isNotEmpty) {
            return Center(
              child: Text(
                'No results found',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            );
          }

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Start searching for your favorite music',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final track = results[index];
              return TrackTile(
                track: track,
                onPlay: () {
                  context.read<PlayerProvider>().playTrack(track);
                },
                onDetails: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TrackDetailsScreen(track: track),
                    ),
                  );
                },
                onLikeToggle: () {
                  // In a real app, toggle like through a provider
                },
              );
            },
          );
        },
      ),
    );
  }
}
