import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ExpiringDocumentsSection extends StatelessWidget {
  const ExpiringDocumentsSection({super.key});

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
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'تنتهي قريباً',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Expiring Documents List
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _ExpiringDocumentCard(
                  title: 'بطاقة الهوية',
                  daysLeft: 15,
                  icon: Icons.badge_outlined,
                  color: AppColors.error,
                ),
                SizedBox(width: 12),
                _ExpiringDocumentCard(
                  title: 'رخصة القيادة',
                  daysLeft: 30,
                  icon: Icons.directions_car_outlined,
                  color: AppColors.warning,
                ),
                SizedBox(width: 12),
                _ExpiringDocumentCard(
                  title: 'جواز السفر',
                  daysLeft: 60,
                  icon: Icons.card_travel_outlined,
                  color: AppColors.info,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiringDocumentCard extends StatelessWidget {
  final String title;
  final int daysLeft;
  final IconData icon;
  final Color color;

  const _ExpiringDocumentCard({
    required this.title,
    required this.daysLeft,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'باقي $daysLeft يوم',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
