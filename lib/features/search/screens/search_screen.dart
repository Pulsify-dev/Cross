import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../../feed/widgets/track_tile.dart';
import '../../player/screens/track_details_screen.dart';
import '../models/search_models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedProvider = context.read<FeedProvider>();
      if (feedProvider.trendingTracks.isEmpty) {
        feedProvider.fetchTrendingTracks();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onHistoryTap(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _searchFocusNode.unfocus();
    _triggerSearch(query);
  }

  void _triggerSearch(String query) {
    _searchFocusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    context.read<SearchProvider>().search(query);
  }

  bool get _isTyping => _searchController.text.isNotEmpty;

  Widget _buildDiscoveryView(
    BuildContext context,
    SearchProvider search,
    FeedProvider feed,
  ) {
    final history = search.searchHistory;
    final trending = feed.trendingTracks;
    final isFocused = _searchFocusNode.hasFocus;

    return ListView(
      children: [
        if (isFocused && history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => search.clearHistory(),
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...history
              .take(5)
              .map(
                (query) => ListTile(
                  leading: const Icon(Icons.history, size: 20),
                  title: Text(query),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => search.removeFromHistory(query),
                  ),
                  onTap: () => _onHistoryTap(query),
                ),
              ),
          const Divider(),
        ],
        if (!isFocused && trending.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trending Now',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...trending.map(
            (track) => TrackTile(
              track: track,
              onPlay: () {
                context.read<PlayerProvider>().playTrack(
                  track,
                  playlist: trending,
                );
              },
              onDetails: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TrackDetailsScreen(track: track),
                  ),
                );
              },
              onLikeToggle: () =>
                  context.read<FeedProvider>().toggleLike(track),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestions(SearchProvider search) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.search, color: Colors.blue),
            title: Text('Search for "$query"'),
            onTap: () => _triggerSearch(query),
          ),
          ...search.suggestions.map(
            (suggestion) => ListTile(
              leading: Icon(
                suggestion.type == 'track'
                    ? Icons.music_note
                    : suggestion.type == 'artist'
                    ? Icons.person
                    : Icons.search,
                size: 20,
              ),
              title: Text(suggestion.text),
              onTap: () {
                _searchController.text = suggestion.text;
                _triggerSearch(suggestion.text);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: false,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search Pulsify...',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: _isTyping
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SearchProvider>().search('');
                          setState(() {
                            _showSuggestions = false;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _showSuggestions = true;
                });
                context.read<SearchProvider>().getSuggestions(value);
              },
              onSubmitted: (value) => _triggerSearch(value),
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: EdgeInsets.symmetric(horizontal: 16),
            tabs: [
              Tab(text: 'Tracks'),
              Tab(text: 'Profiles'),
              Tab(text: 'Playlists'),
              Tab(text: 'Albums'),
            ],
          ),
        ),
        body: Consumer2<SearchProvider, FeedProvider>(
          builder: (context, search, feed, child) {
            if (_showSuggestions && _isTyping) {
              return _buildSuggestions(search);
            }

            if (search.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!_isTyping) {
              return _buildDiscoveryView(context, search, feed);
            }

            if (search.searchResponse.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results found for "${_searchController.text}"',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try searching for something else',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              children: [
                _buildTracksList(search.searchResponse.tracks),
                _buildUsersList(search.searchResponse.users),
                _buildPlaylistsList(search.searchResponse.playlists),
                _buildAlbumsList(search.searchResponse.albums),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTracksList(List<Track> tracks) {
    if (tracks.isEmpty) {
      return const Center(
        child: Text('No tracks found', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return TrackTile(
          track: track,
          onPlay: () {
            context.read<PlayerProvider>().playTrack(track, playlist: tracks);
          },
          onDetails: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TrackDetailsScreen(track: track),
              ),
            );
          },
          onLikeToggle: () => context.read<FeedProvider>().toggleLike(track),
        );
      },
    );
  }

  Widget _buildUsersList(List<User> users) {
    if (users.isEmpty) {
      return const Center(
        child: Text('No profiles found', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? const Icon(Icons.person)
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
        );
      },
    );
  }

  Widget _buildPlaylistsList(List<Playlist> playlists) {
    if (playlists.isEmpty) {
      return const Center(
        child: Text('No playlists found', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return ListTile(
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
          subtitle: Text(
            '${playlist.trackCount} tracks • ${playlist.creator?.displayName ?? 'Unknown'}',
          ),
          onTap: () {
            // Navigate to playlist details
          },
        );
      },
    );
  }

  Widget _buildAlbumsList(List<Album> albums) {
    if (albums.isEmpty) {
      return const Center(
        child: Text('No albums found', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return ListTile(
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
            child: album.artworkUrl == null ? const Icon(Icons.album) : null,
          ),
          title: Text(album.title),
          subtitle: Text('${album.trackCount} tracks • ${album.artistName}'),
          onTap: () {
            // Navigate to album details
          },
        );
      },
    );
  }
}
