import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Trending Now',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        _buildHorizontalTrendingGroup(),
      ],
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

        return SizedBox(
          height:
              280, // Increased height to avoid yellow overflow bar for 3 items
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
  }
}
