//import 'dart:ffi';
//import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/providers/feed_provider.dart';
import '/providers/player_provider.dart';
import '/providers/profile_provider.dart';
import '/routes/route_names.dart';
import '../models/track.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      final feedProvider = context.read<FeedProvider>();
      if (feedProvider.trendingTracks.isEmpty) {
        feedProvider.fetchTrendingTracks();
      }

      final profileProvider = context.read<ProfileProvider>();
      if (profileProvider.profile == null) {
        profileProvider.loadMyProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Pulsify',
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(RouteNames.uploadTrack);
            },
            icon: const Icon(Icons.upload),
            tooltip: 'Upload',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(RouteNames.messages);
            },
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Messages',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, Musician! 👋',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha:0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover New Sounds',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Trending by genre',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildGenreSelector(),
                const SizedBox(height: 20),
                _buildHorizontalTrendingGroup(),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
            Navigator.of(
              context,
            ).pushNamed(RouteNames.trackDetails, arguments: track);
          },
        ),
      ),
    );
  }
}
