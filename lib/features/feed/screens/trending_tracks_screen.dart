//import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../../player/widgets/mini_player.dart';

class TrendingTracksScreen extends StatefulWidget {
  const TrendingTracksScreen({super.key});

  @override
  State<TrendingTracksScreen> createState() => _TrendingTracksScreenState();
}

class _TrendingTracksScreenState extends State<TrendingTracksScreen> {
  final List<String> _genres = [
    'ELECTRONIC',
    'TECHNO',
    'INDIE',
    'HOUSE',
    'LATIN',
    'BASS',
    'AMBIENT',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FeedProvider>();
      if (provider.trendingTracks.isEmpty) {
        provider.fetchTrendingTracks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Glow Effect
          Positioned(
            top: 100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text(
                    'Trending by genre',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                _buildGenreSelector(),
                const SizedBox(height: 16),
                Expanded(child: _buildTrackList()),
              ],
            ),
          ),
          const Positioned(bottom: 0, left: 0, right: 0, child: MiniPlayer()),
        ],
      ),
    );
  }

  Widget _buildGenreSelector() {
    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _genres.map((genre) {
              final isSelected =
                  (provider.selectedGenre?.toUpperCase() ?? 'ELECTRONIC') ==
                  genre;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => provider.setGenre(genre.toLowerCase()),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      color: Colors.transparent,
                    ),
                    child: Text(
                      genre,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTrackList() {
    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        if (provider.isTrendingLoading && provider.trendingTracks.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (provider.trendingTracks.isEmpty) {
          return Center(
            child: Text(
              'No tracks found for this genre.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: provider.trendingTracks.length,
          padding: const EdgeInsets.only(bottom: 100), // Space for MiniPlayer
          itemBuilder: (context, index) {
            final track = provider.trendingTracks[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                onTap: () {
                  context.read<PlayerProvider>().playTrack(
                    track,
                    playlist: provider.trendingTracks,
                  );
                },
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: track.artworkUrl ?? '',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Theme.of(context).colorScheme.surface),
                    errorWidget: (context, url, err) => Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Icon(
                        Icons.music_note,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  track.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  track.artistName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamed(RouteNames.trackDetails, arguments: track);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
