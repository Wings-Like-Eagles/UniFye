import 'package:flutter/material.dart';

/// Dating App Color Palette
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFFFF4B6E); // Romantic Rose
  static const Color primaryDark = Color(0xFFE63956); // Darker shade for pressed states
  static const Color primaryLight = Color(0xFFFF6B85); // Lighter shade for hover
  
  // Secondary Colors
  static const Color secondary = Color(0xFFFFA8C7); // Soft Pink
  static const Color secondaryDark = Color(0xFFFF8FB0);
  
  // Background Colors
  static const Color background = Color(0xFFFFF5F7); // Off-white Blush
  static const Color surface = Color(0xFFFFFFFF); // Pure white for cards
  static const Color surfaceVariant = Color(0xFFFFF0F3); // Subtle pink tint
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A); // Almost black, softer than pure black
  static const Color textSecondary = Color(0xFF7A7A7A); // Cool Gray
  static const Color textTertiary = Color(0xFFAAAAAA); // Light Gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on primary button
  
  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212); // Jet Black
  static const Color darkSurface = Color(0xFF1E1E1E); // Slightly lighter for cards
  static const Color darkSurfaceVariant = Color(0xFF2A2A2A);
  
  // Accent & Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF4B4B);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);
  
  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF3A3A3A);
  static const Color divider = Color(0xFFF0F0F0);
  
  // Gradient for premium features
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow colors
  static const Color shadowLight = Color(0x1AFF4B6E); // Light pink shadow
  static const Color shadowDark = Color(0x40000000); // Dark shadow
}