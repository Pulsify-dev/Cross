import 'package:flutter/material.dart';
import 'package:cross/routes/route_names.dart';
import 'package:cross/features/profile/screens/user_profile_screen.dart';
import 'package:cross/features/edit profile/screens/edit_profile_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const UserProfileScreen());
      case RouteNames.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}