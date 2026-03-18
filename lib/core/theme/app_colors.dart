import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core brand
  static const Color primary = Color(0xFFA855F7);
  static const Color primaryLight = Color(0xFFC084FC);
  static const Color primaryDark = Color(0xFF7E22CE);

  // Main backgrounds
  static const Color background = Color(0xFF191022);
  static const Color backgroundAlt = Color(0xFF140B1C);

  // Surfaces / cards
  static const Color surface = Color(0xFF211B27);
  static const Color surfaceSoft = Color(0xFF1F1629);
  static const Color surfaceElevated = Color(0xFF2A1D38);

  // Inputs / controls
  static const Color inputBackground = Color(0xFF1A1025);
  static const Color chipBackground = Color(0xFF2B183D);
  static const Color divider = Color(0xFF332043);
  static const Color border = Color(0xFF3A2455);

  // Text
  static const Color textPrimary = Color(0xFFF7F5F8);
  static const Color textSecondary = Color(0xFFB9A9C9);
  static const Color textMuted = Color(0xFF8F7CA3);
  static const Color textHint = Color(0xFF766782);

  // Icon colors
  static const Color iconPrimary = Color(0xFFF7F5F8);
  static const Color iconSecondary = Color(0xFFAA97BD);
  static const Color iconMuted = Color(0xFF7C6A90);

  // States
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // Navigation / overlays
  static const Color navBarBackground = Color(0xFF1A1124);
  static const Color overlay = Color(0x99000000);
  static const Color shadow = Color(0x33000000);

  // Special accents for glow / gradients
  static const Color glow = Color(0x66A855F7);
  static const Color gradientStart = Color(0xFF9333EA);
  static const Color gradientEnd = Color(0xFFB968FF);

  // Common semantic aliases
  static const Color cardBackground = surface;
  static const Color subtitle = textSecondary;
}