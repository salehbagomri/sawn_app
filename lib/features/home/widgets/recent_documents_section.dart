import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RecentDocumentsSection extends StatelessWidget {
  const RecentDocumentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'آخر المستندات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Recent Documents List
          _RecentDocumentItem(
            title: 'جواز السفر',
            category: 'شخصي',
            date: 'أمس',
            icon: Icons.card_travel_outlined,
            color: AppColors.categoryPersonal,
          ),
          const SizedBox(height: 12),
          _RecentDocumentItem(
            title: 'فاتورة الكهرباء',
            category: 'السكن',
            date: 'قبل 3 أيام',
            icon: Icons.receipt_outlined,
            color: AppColors.categoryHome,
          ),
          const SizedBox(height: 12),
          _RecentDocumentItem(
            title: 'عقد الإيجار',
            category: 'السكن',
            date: 'قبل أسبوع',
            icon: Icons.description_outlined,
            color: AppColors.categoryHome,
          ),
          const SizedBox(height: 12),
          _RecentDocumentItem(
            title: 'تأمين السيارة',
            category: 'السيارة',
            date: 'قبل أسبوعين',
            icon: Icons.security_outlined,
            color: AppColors.categoryCar,
          ),
        ],
      ),
    );
  }
}

class _RecentDocumentItem extends StatelessWidget {
  final String title;
  final String category;
  final String date;
  final IconData icon;
  final Color color;

  const _RecentDocumentItem({
    required this.title,
    required this.category,
    required this.date,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to document details
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.surfaceVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
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
                    category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              date,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_left,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
