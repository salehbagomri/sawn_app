import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../widgets/expiring_documents_section.dart';
import '../widgets/categories_section.dart';
import '../widgets/recent_documents_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'مستخدم';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً، $userName 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'مستنداتك في أمان',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            // TODO: Notifications
                          },
                          icon: const Badge(
                            label: Text('2'),
                            child: Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.person_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    // TODO: Open search
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.surfaceVariant,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'ابحث في مستنداتك...',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),

            // Expiring Soon Section
            const SliverToBoxAdapter(
              child: ExpiringDocumentsSection(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),

            // Categories Section
            const SliverToBoxAdapter(
              child: CategoriesSection(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),

            // Recent Documents Section
            const SliverToBoxAdapter(
              child: RecentDocumentsSection(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Space for bottom nav
            ),
          ],
        ),
      ),
    );
  }
}
