import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'features/feed/services/api_track_service.dart';
import 'features/feed/services/api_user_service.dart';
import 'features/feed/services/track_service.dart';
import 'features/feed/services/user_service.dart';
import 'providers/auth_provider.dart';
import 'providers/engagement_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/player_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/search_provider.dart';
import 'providers/upload_provider.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';

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
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<TrackService>(
          create: (context) => ApiTrackService(context.read<ApiService>()),
        ),
        Provider<UserService>(
          create: (context) => ApiUserService(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => FeedProvider(
            context.read<TrackService>(),
            context.read<UserService>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => SearchProvider(
            context.read<TrackService>(),
            context.read<UserService>(),
          ),
        ),

        ChangeNotifierProxyProvider<FeedProvider, PlayerProvider>(
          create: (context) =>
              PlayerProvider(trackService: context.read<TrackService>()),
          update: (context, feedProvider, playerProvider) {
            playerProvider!.onTrackStarted = feedProvider.addToHistory;
            return playerProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => EngagementProvider(context.read<TrackService>()),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UploadProvider>(
          create: (_) => UploadProvider(),
          update: (_, authProvider, uploadProvider) {
            final provider = uploadProvider ?? UploadProvider();
            provider.updateCurrentUser(
              userId: authProvider.currentUser?.id,
              username: authProvider.currentUser?.username,
            );
            return provider;
          },
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
