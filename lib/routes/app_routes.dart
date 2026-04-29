import 'package:cross/features/library/screens/library_screen.dart';
import 'package:cross/features/messages/screens/messages_screen.dart';
import 'package:cross/features/messages/models/conversation.dart';
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
import 'package:cross/features/feed/screens/feed_screen.dart';
import 'package:cross/features/player/screens/track_details_screen.dart';
import '../features/feed/models/track.dart';
import 'package:cross/features/library/screens/liked_tracks_screen.dart';
import 'package:cross/features/library/screens/listening_history_screen.dart';
import 'package:cross/features/search/screens/search_results_screen.dart';
import 'package:cross/features/player/screens/track_comments_screen.dart';
import 'package:cross/features/player/screens/track_likes_screen.dart';
import 'package:cross/features/player/screens/track_reposts_screen.dart';
import 'package:cross/features/profile/screens/followers_screen.dart';
import 'package:cross/features/profile/screens/following_screen.dart';
import 'package:cross/features/upload/screens/upload_track_screen.dart';
import 'package:cross/features/upload/screens/edit_uploaded_track_screen.dart';
import 'package:cross/features/profile/screens/blocked_users_screen.dart';
import 'package:cross/features/profile/screens/suggested_users_screen.dart';
import 'package:cross/features/social/screens/mutual_followers_screen.dart';
import 'package:cross/features/social/screens/public_profile_screen.dart';
import 'package:cross/features/messages/screens/chat_screen.dart';

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
        final initialIndex = settings.arguments is int ? settings.arguments as int : 0;
        return MaterialPageRoute(
          builder: (context) => MainScreen(initialIndex: initialIndex),
        );
      case RouteNames.feed:
        return MaterialPageRoute(
          builder: (_) => const FeedScreen(showBottomNavigationBar: true),
        );
      case RouteNames.trackDetails:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => TrackDetailsScreen(
              track: args['track'] as Track,
              playlist: args['playlist'] as List<Track>?,
              isFeedMode: args['isFeedMode'] as bool? ?? false,
            ),
          );
        }
        final track = settings.arguments as Track;
        return MaterialPageRoute(
          builder: (_) => TrackDetailsScreen(track: track),
        );
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
      case RouteNames.reposts:
        final track = settings.arguments as Track;
        return MaterialPageRoute(
          builder: (_) => TrackRepostsScreen(track: track),
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
      case RouteNames.messageThread:
        final convArg = settings.arguments as Conversation;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            userId: convArg.otherUser.id,
            username: convArg.otherUser.username,
            displayName: convArg.otherUser.displayName,
            avatarUrl: convArg.otherUser.profileImageUrl,
          ),
        );
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const UserProfileScreen());
      case RouteNames.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case RouteNames.followers:
        final targetUserId = settings.arguments is String
            ? settings.arguments as String
            : null;
        return MaterialPageRoute(
          builder: (_) => FollowersScreen(targetUserId: targetUserId),
        );

      case RouteNames.following:
        final targetUserId = settings.arguments is String
            ? settings.arguments as String
            : null;
        return MaterialPageRoute(
          builder: (_) => FollowingScreen(targetUserId: targetUserId),
        );

      case RouteNames.uploadTrack:
        return MaterialPageRoute(builder: (_) => const UploadTrackScreen());
      case RouteNames.editUploadedTrack:
        final trackId = settings.arguments is String
            ? settings.arguments as String
            : '';
        return MaterialPageRoute(
          builder: (_) => EditUploadedTrackScreen(trackId: trackId),
        );
      case RouteNames.blockedUsers:
        return MaterialPageRoute(builder: (_) => const BlockedUsersScreen());
      case RouteNames.suggestedUsers:
        return MaterialPageRoute(builder: (_) => const SuggestedUsersScreen());
      case RouteNames.publicProfile:
        final userId = settings.arguments is String
            ? settings.arguments as String
            : '';
        return MaterialPageRoute(
          builder: (_) => PublicProfileScreen(userId: userId),
        );
      case RouteNames.mutualFollowers:
        final userId = settings.arguments is String
            ? settings.arguments as String
            : '';
        return MaterialPageRoute(
          builder: (_) => MutualFollowersScreen(userId: userId),
        );

      case RouteNames.chat:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            userId: args['userId'] as String,
            username: (args['username'] as String?)?.isNotEmpty == true
                ? args['username'] as String
                : args['userId'] as String,
            displayName: args['displayName'] as String,
            avatarUrl: args['avatarUrl'] as String?,
          ),
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
