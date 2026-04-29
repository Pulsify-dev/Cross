import 'package:cross/features/player/widgets/playlist_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/core/theme/app_colors.dart';
import '/providers/feed_provider.dart';
import '/providers/player_provider.dart';
import '/routes/route_names.dart';
import '../models/track.dart';

class TrendingTrackWidget extends StatefulWidget {
  const TrendingTrackWidget({super.key});

  @override
  State<TrendingTrackWidget> createState() => _TrendingTrackWidgetState();
}

class _TrendingTrackWidgetState extends State<TrendingTrackWidget> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Trending by genre',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        _buildGenreSelector(),
        const SizedBox(height: 12),
        _buildHorizontalTrendingGroup(),
      ],
    );
  }

  Widget _buildGenreSelector() {
    final List<Map<String, String>> genres = [
      {'label': 'ELECTRONIC', 'value': 'Electronic'},
      {'label': 'SOUNDCLOUD', 'value': 'SoundCloud'},
      {'label': 'TECHNOHOUSE', 'value': 'TechnoHouse'},
      {'label': 'INDIE', 'value': 'Indie'},
      {'label': 'LATIN', 'value': 'Latin'},
      {'label': 'HIP HOP & RAP', 'value': 'Hip-Hop'},
      {'label': 'ROCK, METAL, PUNK', 'value': 'Rock'},
      {'label': 'COUNTRY', 'value': 'Country'},
      {'label': 'FOLK', 'value': 'Folk'},
      {'label': 'JAZZJAZZ', 'value': 'Jazz'},
      {'label': 'REGGAE', 'value': 'Reggae'},
      {'label': 'POP', 'value': 'Pop'},
      {'label': 'SOUL', 'value': 'Soul'},
      {'label': 'R&B', 'value': 'R&B'},
    ];

    return Consumer<FeedProvider>(
      builder: (context, feed, child) {
        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: genres.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final genre = genres[index];
              final isSelected = (feed.selectedGenre ?? '') == genre['value'];
              
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(
                    genre['label']!,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (selected) {
                    if (selected && !isSelected) {
                      feed.setGenre(genre['value']);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHorizontalTrendingGroup() {
    return Consumer<FeedProvider>(
      builder: (context, feed, child) {
        if (feed.isTrendingLoading && feed.trendingTracks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        final tracks = feed.trendingTracks;
        if (tracks.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No tracks trending right now.'),
            ),
          );
        }

        // Divide tracks into groups of 3 for vertical columns that scroll horizontally
        final List<List<dynamic>> groups = [];
        for (var i = 0; i < tracks.length; i += 3) {
          groups.add(
            tracks.sublist(i, (i + 3 > tracks.length) ? tracks.length : i + 3),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.centerLeft,
              radius: 1.8,
              colors: [
                AppColors.primary.withValues(alpha: 0.25),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6],
            ),
          ),
          child: SizedBox(
            height: 280, // Increased height to avoid yellow overflow bar for 3 items
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: groups.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, groupIndex) {
              final groupItems = groups[groupIndex];
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.85, // Peek effect
                child: Column(
                  children: groupItems
                      .map((track) => _buildTrackTile(track as Track, tracks))
                      .toList(),
                ),
              );
            },
          ),
        ),
        );
      },
    );
  }

  Widget _buildTrackTile(Track track, List<Track> playlist) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () {
          context.read<PlayerProvider>().playTrack(track, playlist: playlist);
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: track.artworkUrl ?? '',
            width: 58,
            height: 58,
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artistName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
       trailing: IconButton(
  icon: Icon(
    Icons.more_vert,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
  ),
  onPressed: () {
    // Show the Bottom Sheet menu
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navBarBackground, // Matches your theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Keep your existing "Go to Details" option
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('View Details', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(RouteNames.trackDetails, arguments: track);
              },
            ),
            // 2. ADD THE NEW PLAYLIST OPTION HERE
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                 Navigator.pop(context); // Closes the 'More' menu
                   showModalBottomSheet(
                    context: context,
                     backgroundColor: const Color(0xFF121212),
                      isScrollControlled: true,
                builder: (context) => PlaylistSelectorSheet(track: track),
                );
              },
            ),
          ],
        ),
      ),
    );
  },
),
      ),
    );    
}
}