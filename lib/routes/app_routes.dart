import 'package:cross/features/library/screens/library_screen.dart';
import 'package:cross/features/messages/screens/messages_screen.dart';
import 'package:cross/features/search/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:cross/features/auth/screens/login_screen.dart';
import 'package:cross/features/auth/screens/register_screen.dart';
import '../features/feed/screens/home_screen.dart';
import 'package:cross/features/profile/screens/user_profile_screen.dart';
import 'package:cross/features/auth/screens/forgot_password_screen.dart';
import 'package:cross/routes/route_names.dart';
import 'package:cross/features/profile/screens/edit_profile_screen.dart';
import 'package:cross/features/home/screens/main_screen.dart';
import 'package:cross/features/feed/screens/activity_feed_screen.dart';
import 'package:cross/features/player/screens/track_details_screen.dart';
import '../features/feed/models/track.dart';
import 'package:cross/features/feed/screens/trending_tracks_screen.dart';
import 'package:cross/features/library/screens/liked_tracks_screen.dart';
import 'package:cross/features/library/screens/listening_history_screen.dart';
import 'package:cross/features/search/screens/search_results_screen.dart';
import 'package:cross/features/player/screens/track_comments_screen.dart';
import 'package:cross/features/player/screens/track_likes_screen.dart';
import 'package:cross/features/profile/screens/followers_screen.dart';
import 'package:cross/features/profile/screens/following_screen.dart';
import 'package:cross/features/upload/screens/upload_track_screen.dart';
import 'package:cross/features/upload/screens/edit_uploaded_track_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case RouteNames.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteNames.mainScreen:
        return MaterialPageRoute(builder: (context) => const MainScreen());
      case RouteNames.activityFeed:
        return MaterialPageRoute(builder: (_) => const ActivityFeedScreen());
      case RouteNames.trackDetails:
        final track = settings.arguments as Track;
        return MaterialPageRoute(
          builder: (_) => TrackDetailsScreen(track: track),
        );
      case RouteNames.trending:
        return MaterialPageRoute(builder: (_) => const TrendingTracksScreen());
      case RouteNames.likedTracks:
        return MaterialPageRoute(builder: (_) => const LikedTracksScreen());
      case RouteNames.library:
        return MaterialPageRoute(builder: (_) => const LibraryScreen());
      case RouteNames.history:
        return MaterialPageRoute(
          builder: (_) => const ListeningHistoryScreen(),
        );
      case RouteNames.comments:
        final track = settings.arguments as Track;
        return MaterialPageRoute(
          builder: (_) => TrackCommentsScreen(track: track),
        );
      case RouteNames.likes:
        final track = settings.arguments as Track;
        return MaterialPageRoute(
          builder: (_) => TrackLikesScreen(track: track),
        );
      case RouteNames.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case RouteNames.searchResults:
        final query = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => SearchResultsScreen(query: query),
        );
      case RouteNames.messages:
        return MaterialPageRoute(builder: (_) => const MessagesScreen());
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const UserProfileScreen());
      case RouteNames.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case RouteNames.followers:
        return MaterialPageRoute(builder: (_) => const FollowersScreen());

      case RouteNames.following:
        return MaterialPageRoute(builder: (_) => const FollowingScreen());

      case RouteNames.uploadTrack:
        return MaterialPageRoute(builder: (_) => const UploadTrackScreen());
      case RouteNames.editUploadedTrack:
        final trackId = settings.arguments is String
            ? settings.arguments as String
            : '';
        return MaterialPageRoute(
          builder: (_) => EditUploadedTrackScreen(trackId: trackId),
        );


      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
