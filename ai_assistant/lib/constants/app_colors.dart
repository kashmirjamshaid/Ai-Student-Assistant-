import 'package:flutter/material.dart';

class AppColors {
  // Gradients
  static const List<Color> primaryGradientColors = [
    Color(0xFF3B82F6), // Vibrant Blue
    Color(0xFF8B5CF6), // Royal Purple
  ];

  static const Gradient primaryGradient = LinearGradient(
    colors: primaryGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient primaryGradientHorizontal = LinearGradient(
    colors: primaryGradientColors,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF8FAFC); // Slate 50
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightAccent = Color(0xFF4F46E5); // Indigo 600
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF0F172A); // Slate 900
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkAccent = Color(0xFF818CF8); // Indigo 400
  static const Color darkBorder = Color(0xFF334155); // Slate 700

  // Status Colors
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
}
