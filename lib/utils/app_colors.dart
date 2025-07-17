import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightCardColor = Colors.white;

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);

  // Common colors
  static const Color primaryColor = Colors.black;
  static const Color accentColor = Colors.blue;
  static const Color errorColor = Colors.red;

  // Step indicator colors
  static const Color activeStepColor = primaryColor;
  static const Color inactiveStepColor = Color(0xFFE0E0E0);

  // Additional colors for home screen
  static const Color primaryDark = Color(0xFF2C3E50);
  static const Color primaryLight = Color(0xFF3498DB);

  // Text Colors
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Colors.white;

  // Gradient Colors
  static const Color gradientBlue = Color(0xFF3498DB);
  static const Color gradientPink = Color(0xFFE74C3C);

  // Status Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningColor = Color(0xFFF39C12); // Added for compatibility

  // Alias for existing colors (to maintain compatibility with both versions)
  static const Color cardDark = darkCardColor;
  static const Color cardLight = lightCardColor;
}