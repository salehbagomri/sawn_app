import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Screens
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/pin_setup_screen.dart';
import '../../features/auth/screens/pin_lock_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/main_layout.dart';
import '../../features/documents/screens/documents_screen.dart';
import '../../features/documents/screens/document_details_screen.dart';
import '../../features/documents/screens/add_document_screen.dart';
import '../../features/reminders/screens/reminders_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

// Route Names
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String pinSetup = '/pin-setup';
  static const String pinLock = '/pin-lock';
  static const String main = '/main';
  static const String home = '/main/home';
  static const String documents = '/main/documents';
  static const String documentDetails = '/document/:id';
  static const String addDocument = '/add-document';
  static const String reminders = '/main/reminders';
  static const String settings = '/main/settings';
}

// Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinSetup,
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinLock,
        builder: (context, state) => const PinLockScreen(),
      ),

      // Main Layout with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.documents,
            pageBuilder: (context, state) {
              final focusSearch = state.uri.queryParameters['search'] == 'true';
              return NoTransitionPage(
                child: DocumentsScreen(focusSearch: focusSearch),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.reminders,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RemindersScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // Document Details
      GoRoute(
        path: AppRoutes.documentDetails,
        builder: (context, state) {
          final documentId = state.pathParameters['id']!;
          return DocumentDetailsScreen(documentId: documentId);
        },
      ),

      // Add Document
      GoRoute(
        path: AppRoutes.addDocument,
        builder: (context, state) => const AddDocumentScreen(),
      ),
    ],

    // Error Page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('الصفحة غير موجودة: ${state.uri}'),
      ),
    ),
  );
});
