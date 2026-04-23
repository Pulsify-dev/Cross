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

          if (searchProvider.searchResponse.isEmpty) {
            return const Center(child: Text('No results found.'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (searchProvider.searchResponse.tracks.isNotEmpty) ...[
                _buildSectionHeader('Tracks'),
                ...searchProvider.searchResponse.tracks.map((track) => TrackTile(
                      track: track,
                      showLike: true,
                      onPlay: () {
                        context.read<PlayerProvider>().playTrack(
                              track,
                              playlist: searchProvider.searchResponse.tracks,
                            );
                      },
                      onDetails: () {
                        Navigator.of(context).pushNamed(
                          RouteNames.trackDetails,
                          arguments: track,
                        );
                      },
                      onLikeToggle: () => context.read<FeedProvider>().toggleLike(track),
                    )),
              ],
              if (searchProvider.searchResponse.users.isNotEmpty) ...[
                _buildSectionHeader('People'),
                ...searchProvider.searchResponse.users.map((user) => ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        child: user.profileImageUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      onTap: () {
                        Navigator.pushNamed(context, RouteNames.publicProfile, arguments: user.id);
                      },
                    )),
              ],
              if (searchProvider.searchResponse.playlists.isNotEmpty) ...[
                _buildSectionHeader('Playlists'),
                ...searchProvider.searchResponse.playlists.map((playlist) => ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: playlist.artworkUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(playlist.artworkUrl!), fit: BoxFit.cover)
                              : null,
                          color: Colors.grey[800],
                        ),
                        child: playlist.artworkUrl == null ? const Icon(Icons.playlist_play) : null,
                      ),
                      title: Text(playlist.name),
                      subtitle: Text(
                          '${playlist.trackCount} tracks • ${playlist.creator?.displayName ?? 'Unknown'}'),
                      onTap: () {
                        // Navigate to playlist details
                      },
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
