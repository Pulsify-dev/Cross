import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core brand — SoundCloud orange
  static const Color primary = Color(0xFFFF5500);
  static const Color primaryLight = Color(0xFFFF7733);
  static const Color primaryDark = Color(0xFFCC4400);

  // Main backgrounds
  static const Color background = Color(0xFF111111);
  static const Color backgroundAlt = Color(0xFF0A0A0A);

  // Surfaces / cards
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceSoft = Color(0xFF161616);
  static const Color surfaceElevated = Color(0xFF222222);

  // Inputs / controls
  static const Color inputBackground = Color(0xFF111111);
  static const Color chipBackground = Color(0xFF222222);
  static const Color divider = Color(0xFF2A2A2A);
  static const Color border = Color(0xFF333333);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textMuted = Color(0xFF666666);
  static const Color textHint = Color(0xFF555555);

  // Icon colors
  static const Color iconPrimary = Color(0xFFFFFFFF);
  static const Color iconSecondary = Color(0xFF888888);
  static const Color iconMuted = Color(0xFF555555);

  // States
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // Navigation / overlays
  static const Color navBarBackground = Color(0xFF0F0F0F);
  static const Color overlay = Color(0x99000000);
  static const Color shadow = Color(0x33000000);

  // Special accents for glow / gradients
  static const Color glow = Color(0x66FF5500);
  static const Color gradientStart = Color(0xFFFF5500);
  static const Color gradientEnd = Color(0xFFFF7733);

  // Common semantic aliases
  static const Color cardBackground = surface;
  static const Color subtitle = textSecondary;
}