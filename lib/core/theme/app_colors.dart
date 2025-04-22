import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFFFFD233);
  static const Color primaryDark = Color(0xFFE0B82D);

  // Background colors
  static const Color background = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color bottomNavBackground = Color(0xFF1A1A1A);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);

  // Status colors
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);

  // Gradients
  static const LinearGradient blackGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Colors.black87,
      Colors.black,
    ],
  );

  static const LinearGradient yellowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      primaryDark,
    ],
  );
}