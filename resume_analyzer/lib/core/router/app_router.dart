import 'package:flutter/material.dart';
import 'package:resume_analyzer/presentation/screens/auth/login_screen.dart';
import 'package:resume_analyzer/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:resume_analyzer/presentation/screens/detail/resume_detail_screen.dart';

/// Simple named-route-based navigation.
/// Keeps it straightforward for a mobile-first app.
class AppRouter {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String detail = '/detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _fadeRoute(const LoginScreen(), settings);
      case dashboard:
        return _fadeRoute(const DashboardScreen(), settings);
      case detail:
        return _slideRoute(const ResumeDetailScreen(), settings);
      default:
        return _fadeRoute(const LoginScreen(), settings);
    }
  }

  /// Smooth fade transition.
  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Slide from right transition (for detail screens).
  static PageRouteBuilder _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
