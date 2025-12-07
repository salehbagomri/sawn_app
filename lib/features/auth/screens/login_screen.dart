import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final result = await ref.read(currentUserProvider.notifier).signInWithGoogle();

      if (!mounted) return;

      if (result.isSuccess) {
        // Check if user has PIN enabled for security
        if (result.user?.pinEnabled == true) {
          context.go(AppRoutes.pinLock);
        } else {
          // Go directly to home - PIN setup is optional in settings
          context.go(AppRoutes.home);
        }
      } else if (result.hasError) {
        _showError(result.errorMessage ?? 'حدث خطأ أثناء تسجيل الدخول');
      }
      // If cancelled, do nothing
    } catch (e) {
      _showError('حدث خطأ غير متوقع');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.logoGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'ص',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Name
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 36,
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

              const Spacer(flex: 2),

              // Google Sign In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                    side: BorderSide(color: AppColors.getBorder(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google Logo (using icon instead of network image)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceVariantDark : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.g_mobiledata,
                                size: 24,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'المتابعة بحساب Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.getTextPrimary(context),
                                fontFamily: 'Rubik',
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Why Google explanation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceVariant(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outlined,
                      color: AppColors.getTextSecondary(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'نستخدم حساب Google لحفظ مستنداتك بأمان في Google Drive الخاص بك',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.getTextSecondary(context),
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Terms
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text.rich(
                  TextSpan(
                    text: 'بالمتابعة، أنت توافق على ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextTertiary(context),
                      fontFamily: 'Rubik',
                    ),
                    children: [
                      TextSpan(
                        text: 'شروط الاستخدام',
                        style: TextStyle(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' و'),
                      TextSpan(
                        text: 'سياسة الخصوصية',
                        style: TextStyle(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
