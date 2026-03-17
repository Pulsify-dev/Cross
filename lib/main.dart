import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_theme.dart';
import 'package:cross/routes/app_routes.dart';
import 'package:cross/routes/route_names.dart';

void main() {
  runApp(const PulsifyApp());
}

class PulsifyApp extends StatelessWidget {
  const PulsifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: RouteNames.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}