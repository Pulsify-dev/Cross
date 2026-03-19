import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/feed_provider.dart';
import 'providers/player_provider.dart';
import 'providers/search_provider.dart';
import 'features/feed/services/mock_track_service.dart';
import 'providers/engagement_provider.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';
import 'providers/profile_provider.dart';

void main() {
  runApp(const PulsifyApp());
}

class PulsifyApp extends StatelessWidget {
  const PulsifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final trackService = MockTrackService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider(trackService)),
        ChangeNotifierProvider(create: (_) => SearchProvider(trackService)),
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(trackService: trackService),
        ),
        ChangeNotifierProvider(create: (_) => EngagementProvider(trackService)),
      ],
      child: MaterialApp(
        title: 'Pulsify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: RouteNames.mainScreen,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
