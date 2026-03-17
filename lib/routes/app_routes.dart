import 'package:flutter/material.dart';
import 'package:cross/features/auth/screens/login_screen.dart';
import 'package:cross/features/auth/screens/register_screen.dart';
import 'package:cross/features/feed/screens/home_feed_screen.dart';
import 'package:cross/features/profile/screens/user_profile_screen.dart';
import 'package:cross/features/auth/screens/forgot_password_screen.dart';
import 'package:cross/routes/route_names.dart';
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
        return MaterialPageRoute(builder: (_) => const HomeFeedScreen());
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const UserProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}