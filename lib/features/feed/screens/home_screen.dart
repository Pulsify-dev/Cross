//import 'dart:ffi';
//import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/providers/feed_provider.dart';
import '/providers/player_provider.dart';
import '/providers/profile_provider.dart';
import '/features/profile/models/profile_data.dart';
import '/routes/route_names.dart';
import '../models/track.dart';
import '../widgets/trending_track_widget.dart';
import '../widgets/suggested_users_widget.dart';
import '../widgets/listening_history_widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const HomeScreen({super.key, this.onProfileTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                widget.onProfileTap?.call();
                //Navigator.of(context).pushNamed(RouteNames.profile);
              },
              child: Hero(
                tag: 'profile_avatar',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  child: Consumer<ProfileProvider>(
                    builder: (context, profileProvider, _) {
                      final profile = profileProvider.profile;
                      return CircleAvatar(
                        radius: 16,
                        backgroundImage: avatarImage(
                          path: profile?.avatarPath,
                          bytes: profile?.avatarBytes,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child:
                            profile?.avatarPath == null &&
                                profile?.avatarBytes == null
                            ? Icon(
                                Icons.person,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ),
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
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
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
          SliverToBoxAdapter(child: const TrendingTrackWidget()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(child: ListeningHistoryWidget()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: const SuggestedUsersWidget()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
