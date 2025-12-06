import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التنبيهات'),
      ),
      body: const Center(
        child: Text(
          'شاشة التنبيهات - سيتم تطويرها',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
