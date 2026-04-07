import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../../feed/widgets/track_tile.dart';
import '../../player/screens/track_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {})); // rebuild on tab switch
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onHistoryTap(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    context.read<SearchProvider>().search(query);
    setState(() {});
  }

  bool get _isTyping => _searchController.text.isNotEmpty;

  Widget _buildHistory(
    BuildContext context,
    SearchProvider search,
    List<String> history,
    void Function(String) onRemove,
    VoidCallback onClearAll,
  ) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent searches',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: onClearAll,
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(
                  'Delete All',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final query = history[index];
              return ListTile(
                leading: Icon(
                  Icons.history,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                title: Text(query),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  tooltip: 'Remove',
                  onPressed: () => onRemove(query),
                ),
                onTap: () => _onHistoryTap(query),
              );
            },
          ),
        ),
      ],
    );
  }

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
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            border: InputBorder.none,
            suffixIcon: _isTyping
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<SearchProvider>().search('');
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            context.read<SearchProvider>().search(value);
            setState(() {});
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tracks'),
            Tab(text: 'People'),
          ],
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (context, search, child) {
          if (search.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Empty query — show per-tab history ─────────────────────────
          if (!_isTyping) {
            return TabBarView(
              controller: _tabController,
              children: [
                // Tracks history
                _buildHistory(
                  context,
                  search,
                  search.trackHistory,
                  search.removeFromTrackHistory,
                  search.clearTrackHistory,
                ),
                // Users history
                _buildHistory(
                  context,
                  search,
                  search.userHistory,
                  search.removeFromUserHistory,
                  search.clearUserHistory,
                ),
              ],
            );
          }

          // ── No results  ────────────────────────────────────────────────
          if (search.searchResults.isEmpty &&
              search.userSearchResults.isEmpty) {
            return Center(
              child: Text(
                'No results found',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            );
          }

          // ── Results ────────────────────────────────────────────────────
          return TabBarView(
            controller: _tabController,
            children: [
              // Tracks Tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: search.searchResults.length,
                itemBuilder: (context, index) {
                  final track = search.searchResults[index];
                  return TrackTile(
                    track: track,
                    showLike: true,
                    onPlay: () {
                      search.recordTrackSearch(_searchController.text);
                      context.read<PlayerProvider>().playTrack(
                        track,
                        playlist: search.searchResults,
                      );
                    },
                    onDetails: () {
                      search.recordTrackSearch(_searchController.text);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TrackDetailsScreen(track: track),
                        ),
                      );
                    },
                    onLikeToggle: () {
                      context.read<FeedProvider>().toggleLike(track);
                    },
                  );
                },
              ),
              // People Tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: search.userSearchResults.length,
                itemBuilder: (context, index) {
                  final user = search.userSearchResults[index];
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
                    onTap: () async {
                      final profile = await search.getPublicProfile(user.id);
                      if (profile != null && context.mounted) {
                        search.recordUserSearch(_searchController.text);
                        // Navigator.pushNamed(
                        //context,
                        //RouteNames.publicProfile,
                        //arguments: profile,
                        //);
                      }
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
