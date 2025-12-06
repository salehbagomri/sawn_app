import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التصنيفات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Categories Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CategoryCard(
                title: 'شخصي',
                count: 12,
                icon: Icons.person_outlined,
                color: AppColors.categoryPersonal,
              ),
              _CategoryCard(
                title: 'السيارة',
                count: 4,
                icon: Icons.directions_car_outlined,
                color: AppColors.categoryCar,
              ),
              _CategoryCard(
                title: 'العمل',
                count: 8,
                icon: Icons.work_outlined,
                color: AppColors.categoryWork,
              ),
              _CategoryCard(
                title: 'السكن',
                count: 3,
                icon: Icons.home_outlined,
                color: AppColors.categoryHome,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _CategoryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to category documents
      },
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceVariant,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
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
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
