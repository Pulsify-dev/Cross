import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cross/core/theme/app_theme.dart';
import 'package:cross/providers/feed_provider.dart';
import 'package:cross/providers/profile_provider.dart';
import 'package:cross/providers/search_provider.dart';
import 'package:cross/routes/app_routes.dart';
import 'package:cross/routes/route_names.dart';
import 'package:cross/features/feed/services/track_service.dart';
import 'package:cross/features/feed/services/mock_track_service.dart';

void main() {
  runApp(const PulsifyApp());
}

class PulsifyApp extends StatelessWidget {
  const PulsifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
          create: (_) => ProfileProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: RouteNames.login,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}