import 'package:flutter/material.dart';

/// Curated color palette for a premium light-themed SaaS app.
/// Avoids pure white — uses warm off-whites and soft neutrals.
class AppColors {
  AppColors._();

  // ── Brand ──
  static const Color primary = Color(0xFF4F6AF0);       // Soft indigo-blue
  static const Color primaryLight = Color(0xFFE8ECFD);   // Very light indigo
  static const Color primaryDark = Color(0xFF3A50C2);    // Deeper indigo
  static const Color secondary = Color(0xFF7C5CFC);      // Soft violet

  // ── Semantic ──
  static const Color success = Color(0xFF34C759);         // Vibrant green
  static const Color successLight = Color(0xFFE8F9ED);    // Light green bg
  static const Color warning = Color(0xFFF5A623);         // Warm amber
  static const Color warningLight = Color(0xFFFFF5E0);    // Light amber bg
  static const Color error = Color(0xFFEF4444);           // Crisp red
  static const Color errorLight = Color(0xFFFEECEC);      // Light red bg
  static const Color info = Color(0xFF3B82F6);            // Info blue

  // ── Neutrals ──
  static const Color background = Color(0xFFF8F9FC);     // Off-white (warm)
  static const Color surface = Color(0xFFF1F3F8);        // Slightly darker off-white
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white for cards (contrast)
  static const Color inputFill = Color(0xFFF5F6FA);      // Input background
  static const Color chipBackground = Color(0xFFF0F1F5); // Chip background

  // ── Borders ──
  static const Color border = Color(0xFFE8EAF0);         // Soft border
  static const Color borderLight = Color(0xFFF0F1F5);    // Lighter border
  static const Color divider = Color(0xFFEEEFF3);        // Divider

  // ── Text ──
  static const Color textPrimary = Color(0xFF1A1D2E);    // Near-black
  static const Color textSecondary = Color(0xFF6B7280);   // Medium gray
  static const Color textTertiary = Color(0xFF9CA3AF);    // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF);   // White on primary

  // ── Shadows ──
  static const Color shadowLight = Color(0x0A000000);     // 4% opacity
  static const Color shadowMedium = Color(0x14000000);    // 8% opacity

  // ── Gradient presets ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F6AF0), Color(0xFF7C5CFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scoreGradient = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF4F6AF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Returns a color for the ATS score based on value (0-100).
  static Color scoreColor(int score) {
    if (score >= 80) return success;
    if (score >= 60) return primary;
    if (score >= 40) return warning;
    return error;
  }

  /// Returns a light background color for the ATS score.
  static Color scoreLightColor(int score) {
    if (score >= 80) return successLight;
    if (score >= 60) return primaryLight;
    if (score >= 40) return warningLight;
    return errorLight;
  }

  /// Returns a descriptive label for the ATS score.
  static String scoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Needs Work';
    return 'Poor';
  }
}
