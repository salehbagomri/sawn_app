import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class AddDocumentScreen extends StatelessWidget {
  const AddDocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إضافة مستند'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر طريقة الإضافة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Scan Option
            _AddOptionCard(
              icon: Icons.camera_alt_outlined,
              title: 'مسح ضوئي',
              subtitle: 'التقط صورة للمستند بالكاميرا',
              color: AppColors.primary,
              onTap: () {
                // TODO: Open camera scanner
              },
            ),
            const SizedBox(height: 16),
            
            // Upload PDF Option
            _AddOptionCard(
              icon: Icons.picture_as_pdf_outlined,
              title: 'رفع ملف PDF',
              subtitle: 'اختر ملف PDF من جهازك',
              color: AppColors.error,
              onTap: () {
                // TODO: Open file picker for PDF
              },
            ),
            const SizedBox(height: 16),
            
            // Gallery Option
            _AddOptionCard(
              icon: Icons.photo_library_outlined,
              title: 'من المعرض',
              subtitle: 'اختر صورة من معرض الصور',
              color: AppColors.secondary,
              onTap: () {
                // TODO: Open image picker
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AddOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
