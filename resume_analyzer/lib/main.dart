import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/router/app_router.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';

import 'data/database/database_helper.dart';
import 'data/models/resume_history_model.dart';
import 'package:uuid/uuid.dart';

Future<void> _seedDatabase() async {
  final db = DatabaseHelper.instance;
  final resumes = await db.readAllResumes();
  if (resumes.isEmpty) {
    await db.create(ResumeHistoryModel(
      id: const Uuid().v4(),
      title: 'Sample Software Engineer Resume',
      summary: 'A strong resume with excellent backend experience but lacking some cloud deployment details.',
      score: 85.0,
      createdAt: DateTime.now(),
    ));
    await db.create(ResumeHistoryModel(
      id: const Uuid().v4(),
      title: 'Sample Product Manager Resume',
      summary: 'Good product sense demonstrated. Could use more concrete metrics in the experience section.',
      score: 72.5,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ));
    print('Database seeded with sample resumes.');
  } else {
    print('Database already contains ${resumes.length} resumes.');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize and seed database
  await _seedDatabase();

  // Set system UI overlay style for premium light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock to portrait for mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: ResumeAnalyzerApp()));
}

class ResumeAnalyzerApp extends ConsumerWidget {
  const ResumeAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Resume Analyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRouter.generateRoute,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
        loading: () => const _SplashScreen(),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}

/// Premium splash screen shown while Firebase initializes auth state.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Resume Analyzer',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
