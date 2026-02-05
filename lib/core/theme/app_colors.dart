import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors - Purple theme from Doctor Appointment design
  static const Color primary = Color(0xFF8B5CF6); // Main Purple
  static const Color secondary = Color(0xFFA78BFA); // Light Purple
  static const Color tertiary = Color(0xFFC4B5FD); // Lighter Purple
  static const Color accent = Color(0xFFE9D5FF); // Pale Purple

  // Background colors
  static const Color background =
      Color(0xFFFAF5FF); // Very light purple tint background
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF8B5CF6);

  // Chart colors
  static const Color normalStatus = Color(0xFF10B981);
  static const Color highStatus = Color(0xFFEF4444);
  static const Color lowStatus = Color(0xFFF59E0B);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [tertiary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
