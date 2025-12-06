import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/document_provider.dart';
import '../widgets/expiring_documents_section.dart';
import '../widgets/categories_section.dart';
import '../widgets/recent_documents_section.dart';
import '../widgets/favorites_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = _getFirstName(user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? 'مستخدم');
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final unreadCount = ref.watch(unreadRemindersCountProvider);
    final stats = ref.watch(documentStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(expiringDocumentsProvider);
            ref.invalidate(favoriteDocumentsProvider);
            ref.invalidate(recentDocumentsProvider);
            ref.invalidate(categoryCounts);
            ref.invalidate(unreadRemindersCountProvider);
            ref.invalidate(documentStatsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحباً، $userName',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            stats.when(
                              data: (data) {
                                final expiring = data['expiringSoon'] ?? 0;
                                if (expiring > 0) {
                                  return Text(
                                    '$expiring مستندات تنتهي قريباً',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.warning,
                                    ),
                                  );
                                }
                                return const Text(
                                  'مستنداتك في أمان',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              },
                              loading: () => const Text(
                                'جاري التحميل...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              error: (_, __) => const Text(
                                'مستنداتك في أمان',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Notifications Button
                          IconButton(
                            onPressed: () {
                              context.go('/main/reminders');
                            },
                            icon: unreadCount.when(
                              data: (count) => count > 0
                                  ? Badge(
                                      label: Text('$count'),
                                      child: const Icon(
                                        Icons.notifications_outlined,
                                        color: AppColors.textPrimary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.notifications_outlined,
                                      color: AppColors.textPrimary,
                                    ),
                              loading: () => const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.textPrimary,
                              ),
                              error: (_, __) => const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Profile Avatar
                          GestureDetector(
                            onTap: () {
                              context.go('/main/settings');
                            },
                            child: avatarUrl != null
                                ? CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(avatarUrl),
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  )
                                : CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.person_outlined,
                                      color: AppColors.primary,
                                    ),
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
                      // Navigate to documents with search focus
                      context.push('/main/documents?search=true');
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

              // Favorites Section (shows only if there are favorites)
              const SliverToBoxAdapter(
                child: FavoritesSection(),
              ),

              // Spacing after favorites (only if favorites exist)
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, _) {
                    final favorites = ref.watch(favoriteDocumentsProvider);
                    return favorites.when(
                      data: (docs) => docs.isNotEmpty
                          ? const SizedBox(height: 24)
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
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
      ),
    );
  }

  String _getFirstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }
}
