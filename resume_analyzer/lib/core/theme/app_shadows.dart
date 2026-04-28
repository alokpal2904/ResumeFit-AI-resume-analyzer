import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Consistent, subtle shadow presets for premium elevation.
class AppShadows {
  AppShadows._();

  /// Minimal shadow for flat cards.
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Standard card shadow.
  static List<BoxShadow> get md => [
        BoxShadow(
          color: AppColors.shadowMedium,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Elevated card / modal shadow.
  static List<BoxShadow> get lg => [
        BoxShadow(
          color: AppColors.shadowMedium,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Floating button / FAB shadow.
  static List<BoxShadow> get fab => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
