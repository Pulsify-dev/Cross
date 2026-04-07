import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/feed/services/mock_track_service.dart';
import 'features/feed/services/track_service.dart';
import 'providers/auth_provider.dart';
import 'providers/engagement_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/player_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/search_provider.dart';
import 'providers/upload_provider.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';
import 'providers/playlist_provider.dart';

void main() {
  runApp(const PulsifyApp());
}

class PulsifyApp extends StatelessWidget {
  const PulsifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkLoginStatus(),
        ),

        Provider<TrackService>(
          create: (_) => MockTrackService(),
        ),

        ChangeNotifierProvider(
          create: (context) => FeedProvider(
            context.read<TrackService>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => SearchProvider(
            context.read<TrackService>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => PlayerProvider(
            trackService: context.read<TrackService>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => EngagementProvider(
            context.read<TrackService>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => ProfileProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => UploadProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PlaylistProvider(),
        ),
      
      ],
      child: MaterialApp(
        title: 'Pulsify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: RouteNames.login,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}