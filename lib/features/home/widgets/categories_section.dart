import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/document_model.dart';
import '../../../core/providers/document_provider.dart';

class CategoriesSection extends ConsumerWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryCountsAsync = ref.watch(categoryCounts);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التصنيفات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 16),

          // Categories Grid
          categoryCountsAsync.when(
            data: (counts) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CategoryCard(
                  title: 'شخصي',
                  count: counts['personal'] ?? 0,
                  icon: Icons.person_outlined,
                  color: AppColors.categoryPersonal,
                  category: DocumentCategory.personal,
                ),
                _CategoryCard(
                  title: 'السيارة',
                  count: counts['car'] ?? 0,
                  icon: Icons.directions_car_outlined,
                  color: AppColors.categoryCar,
                  category: DocumentCategory.car,
                ),
                _CategoryCard(
                  title: 'العمل',
                  count: counts['work'] ?? 0,
                  icon: Icons.work_outlined,
                  color: AppColors.categoryWork,
                  category: DocumentCategory.work,
                ),
                _CategoryCard(
                  title: 'السكن',
                  count: counts['home'] ?? 0,
                  icon: Icons.home_outlined,
                  color: AppColors.categoryHome,
                  category: DocumentCategory.home,
                ),
              ],
            ),
            loading: () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => Container(
                  width: 76,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getSurfaceVariant(context)),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            ),
            error: (_, __) => const Center(
              child: Text(
                'خطأ في تحميل التصنيفات',
                style: TextStyle(color: AppColors.error),
              ),
            ),
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
  final DocumentCategory category;

  const _CategoryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to documents filtered by category
        context.push('/main/documents?category=${category.nameEn}');
      },
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.getSurfaceVariant(context),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.getTextTertiary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
