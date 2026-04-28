import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../../../features/feed/widgets/track_tile.dart';

class ListeningHistoryScreen extends StatefulWidget {
  const ListeningHistoryScreen({super.key});

  @override
  State<ListeningHistoryScreen> createState() => _ListeningHistoryScreenState();
}

class _ListeningHistoryScreenState extends State<ListeningHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchListeningHistory();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FeedProvider>().fetchMoreHistory();
    }
  }

  Future<void> _showClearConfirmation() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear your entire listening history? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (shouldClear == true && mounted) {
      await context.read<FeedProvider>().clearListeningHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listening history cleared')),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 8) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} min${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening History'),
        actions: [
          Consumer<FeedProvider>(
            builder: (context, provider, child) {
              if (provider.listeningHistory.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear History',
                onPressed: _showClearConfirmation,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<FeedProvider>(
              builder: (context, provider, child) {
                if (provider.isHistoryLoading && provider.listeningHistory.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.listeningHistory.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => provider.fetchListeningHistory(),
                    child: ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No history yet. Start listening!')),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchListeningHistory(),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.listeningHistory.length + (provider.hasMoreHistory ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.listeningHistory.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final historyEntry = provider.listeningHistory[index];
                      final track = historyEntry.track;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0 || _formatTimeAgo(historyEntry.playedAt) != _formatTimeAgo(provider.listeningHistory[index - 1].playedAt))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Text(
                                _formatTimeAgo(historyEntry.playedAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          TrackTile(
                            track: track,
                            onPlay: () {
                              context.read<PlayerProvider>().playTrack(
                                track,
                                playlist: provider.listeningHistory.map((e) => e.track).toList(),
                              );
                            },
                            onDetails: () {
                              Navigator.of(context).pushNamed(RouteNames.trackDetails, arguments: track);
                            },
                            onLikeToggle: () => context.read<FeedProvider>().toggleLike(track),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
