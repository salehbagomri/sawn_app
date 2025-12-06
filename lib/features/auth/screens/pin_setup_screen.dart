import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../widgets/pin_input_widget.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _storage = const FlutterSecureStorage();
  String _firstPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  void _onPinEntered(String pin) async {
    if (!_isConfirming) {
      // First entry
      setState(() {
        _firstPin = pin;
        _isConfirming = true;
        _errorMessage = '';
      });
    } else {
      // Confirmation entry
      if (pin == _firstPin) {
        // Save PIN
        await _storage.write(key: 'user_pin', value: pin);
        if (mounted) {
          context.go(AppRoutes.home);
        }
      } else {
        setState(() {
          _errorMessage = 'الرمز غير متطابق، حاول مرة أخرى';
          _isConfirming = false;
          _firstPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                _isConfirming ? 'تأكيد الرمز السري' : 'إنشاء رمز سري',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                _isConfirming
                    ? 'أعد إدخال الرمز السري للتأكيد'
                    : 'أنشئ رمز سري من 4 أرقام لحماية مستنداتك',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // PIN Input
              PinInputWidget(
                onCompleted: _onPinEntered,
                key: ValueKey(_isConfirming),
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

              const SizedBox(height: 32),

              // Skip Option (optional)
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('تخطي الآن'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
