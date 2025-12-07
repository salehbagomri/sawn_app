import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometric auth on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateWithBiometrics();
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canAuthenticate || !isDeviceSupported) {
        // If biometrics not available, go directly to home
        if (mounted) {
          context.go(AppRoutes.home);
        }
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'استخدم البصمة لفتح التطبيق',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'المصادقة مطلوبة',
            biometricHint: 'تحقق من هويتك',
            biometricNotRecognized: 'لم يتم التعرف. حاول مرة أخرى.',
            biometricSuccess: 'تم التحقق بنجاح',
            cancelButton: 'إلغاء',
            deviceCredentialsRequiredTitle: 'مطلوب رمز القفل',
            deviceCredentialsSetupDescription: 'يرجى إعداد رمز قفل الجهاز',
            goToSettingsButton: 'الإعدادات',
            goToSettingsDescription: 'لم يتم إعداد المصادقة البيومترية. يرجى الذهاب للإعدادات.',
          ),
          IOSAuthMessages(
            cancelButton: 'إلغاء',
            goToSettingsButton: 'الإعدادات',
            goToSettingsDescription: 'يرجى إعداد المصادقة البيومترية.',
            lockOut: 'يرجى إعادة تفعيل المصادقة البيومترية',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/Pattern as fallback
        ),
      );

      if (authenticated && mounted) {
        context.go(AppRoutes.home);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'فشل التحقق من الهوية';
        });
      }
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء التحقق';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),

                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // App Name
                Text(
                  'صَوْن',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'التطبيق مقفل',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),

                const Spacer(),

                // Biometric Button
                GestureDetector(
                  onTap: _isAuthenticating ? null : _authenticateWithBiometrics,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _isAuthenticating
                          ? AppColors.primary.withValues(alpha: 0.05)
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: _isAuthenticating
                        ? const Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.fingerprint,
                            size: 56,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  _isAuthenticating ? 'جاري التحقق...' : 'اضغط للفتح بالبصمة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 14,
                  ),
                ),

                // Error Message
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
