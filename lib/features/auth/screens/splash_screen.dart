import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/document_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkAuthStatus();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for animation and minimum splash time
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (isFirstTime) {
      // First time user - show onboarding
      context.go(AppRoutes.onboarding);
      return;
    }

    // Check if user is authenticated
    final authResult = await ref.read(authServiceProvider).checkAuthState();

    if (!mounted) return;

    if (authResult.isSuccess && authResult.user != null) {
      final user = authResult.user!;
      debugPrint('SplashScreen: User authenticated - ${user.name} (${user.id})');

      // Set user ID in document service and reschedule reminders
      final docService = DocumentService();
      docService.setUserId(user.id);

      debugPrint('SplashScreen: Starting to reschedule reminders...');
      final rescheduledCount = await docService.rescheduleAllReminders();
      debugPrint('SplashScreen: Rescheduled $rescheduledCount reminders from cloud');

      if (!mounted) return;

      // Check if app lock (biometric) is enabled
      final appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      debugPrint('SplashScreen: App lock enabled: $appLockEnabled');

      if (appLockEnabled) {
        context.go(AppRoutes.pinLock);
      } else {
        context.go(AppRoutes.home);
      }
    } else {
      // Not authenticated - go to login
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container with gradient
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.logoGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'ص',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Name
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                        fontFamily: 'Rubik',
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      AppConstants.appTagline,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.getTextSecondary(context),
                        fontFamily: 'Rubik',
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading indicator
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
