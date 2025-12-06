import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/main/home')) return 0;
    if (location.startsWith('/main/documents')) return 1;
    if (location.startsWith('/main/reminders')) return 2;
    if (location.startsWith('/main/settings')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.documents);
        break;
      case 2:
        context.go(AppRoutes.reminders);
        break;
      case 3:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addDocument),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.surface,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'الرئيسية',
                index: 0,
                currentIndex: currentIndex,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.folder_outlined,
                activeIcon: Icons.folder,
                label: 'مستنداتي',
                index: 1,
                currentIndex: currentIndex,
              ),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(
                context: context,
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                label: 'التنبيهات',
                index: 2,
                currentIndex: currentIndex,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'الإعدادات',
                index: 3,
                currentIndex: currentIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
  }) {
    final isActive = index == currentIndex;

    return InkWell(
      onTap: () => _onItemTapped(context, index),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppColors.primary : AppColors.textTertiary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
