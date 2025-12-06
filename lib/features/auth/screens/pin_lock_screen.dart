import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../widgets/pin_input_widget.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  String _errorMessage = '';
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      if (canAuthenticate) {
        _authenticateWithBiometrics();
      }
    } catch (e) {
      // Biometrics not available
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'استخدم البصمة لفتح التطبيق',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onPinEntered(String pin) async {
    final savedPin = await _storage.read(key: 'user_pin');

    if (pin == savedPin) {
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } else {
      setState(() {
        _attempts++;
        if (_attempts >= 5) {
          _errorMessage = 'تجاوزت عدد المحاولات المسموحة';
        } else {
          _errorMessage = 'الرمز غير صحيح، تبقى ${5 - _attempts} محاولات';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // App Name
              const Text(
                'صَوْن',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'أدخل الرمز السري',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // PIN Input
              PinInputWidget(
                onCompleted: _onPinEntered,
                key: ValueKey(_attempts),
              ),

              // Error Message
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
              ],

              const Spacer(),

              // Biometric Button
              IconButton(
                onPressed: _authenticateWithBiometrics,
                icon: const Icon(
                  Icons.fingerprint,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'استخدم البصمة',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
