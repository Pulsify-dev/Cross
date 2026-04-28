import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../../feed/widgets/track_tile.dart';
import '../../social/widgets/avatar_url_utils.dart';

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
                ...searchProvider.searchResponse.tracks.map(
                  (track) => TrackTile(
                    track: track,
                    onPlay: () {
                      context.read<PlayerProvider>().playTrack(
                        track,
                        playlist: searchProvider.searchResponse.tracks,
                      );
                    },
                    onDetails: () {
                      Navigator.of(
                        context,
                      ).pushNamed(RouteNames.trackDetails, arguments: {
                        'track': track,
                        'playlist': searchProvider.searchResponse.tracks,
                      });
                    },
                    onLikeToggle: () =>
                        context.read<FeedProvider>().toggleLike(track),
                  ),
                ),
              ],
              if (searchProvider.searchResponse.users.isNotEmpty) ...[
                _buildSectionHeader('People'),
                ...searchProvider.searchResponse.users.map(
                  (user) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceElevated,
                      backgroundImage:
                          isValidNetworkAvatarUrl(user.profileImageUrl)
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: !isValidNetworkAvatarUrl(user.profileImageUrl)
                          ? const Icon(
                              Icons.person,
                              color: Color.fromARGB(255, 220, 218, 218),
                            )
                          : null,
                    ),
                    title: Text(user.displayName),
                    subtitle: Text('@${user.username}'),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RouteNames.publicProfile,
                        arguments: user.id,
                      );
                    },
                  ),
                ),
              ],
              if (searchProvider.searchResponse.playlists.isNotEmpty) ...[
                _buildSectionHeader('Playlists'),
                ...searchProvider.searchResponse.playlists.map(
                  (playlist) => ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        image: playlist.artworkUrl != null
                            ? DecorationImage(
                                image: NetworkImage(playlist.artworkUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey[800],
                      ),
                      child: playlist.artworkUrl == null
                          ? const Icon(Icons.playlist_play)
                          : null,
                    ),
                    title: Text(playlist.name),
                    subtitle: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (playlist.creator?.profileImageUrl != null) ...[
                          CircleAvatar(
                            radius: 8,
                            backgroundImage: NetworkImage(
                              playlist.creator!.profileImageUrl!,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            '${playlist.trackCount} tracks • ${playlist.creator?.displayName ?? 'Unknown'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // onTap: () {
                    //   // TODO: Implement playlist navigation
                    // },
                  ),
                ),
              ],
              if (searchProvider.searchResponse.albums.isNotEmpty) ...[
                _buildSectionHeader('Albums'),
                ...searchProvider.searchResponse.albums.map(
                  (album) => ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        image: album.artworkUrl != null
                            ? DecorationImage(
                                image: NetworkImage(album.artworkUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey[800],
                      ),
                      child: album.artworkUrl == null
                          ? const Icon(Icons.album)
                          : null,
                    ),
                    title: Text(album.title),
                    subtitle: Text(
                      '${album.trackCount} tracks • ${album.artistName}',
                    ),
                    // onTap: () {
                    //   // TODO: Implement album navigation
                    // },
                  ),
                ),
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
