import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Section
          _SettingsSection(
            title: 'الحساب',
            children: [
              _SettingsItem(
                icon: Icons.person_outlined,
                title: 'الملف الشخصي',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.lock_outlined,
                title: 'تغيير الرمز السري',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.fingerprint,
                title: 'البصمة',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // App Settings
          _SettingsSection(
            title: 'التطبيق',
            children: [
              _SettingsItem(
                icon: Icons.language_outlined,
                title: 'اللغة',
                subtitle: 'العربية',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.dark_mode_outlined,
                title: 'الوضع الليلي',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.notifications_outlined,
                title: 'الإشعارات',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Backup & Storage
          _SettingsSection(
            title: 'النسخ الاحتياطي',
            children: [
              _SettingsItem(
                icon: Icons.cloud_upload_outlined,
                title: 'النسخ الاحتياطي التلقائي',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.storage_outlined,
                title: 'التخزين',
                subtitle: '250 MB من 1 GB',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // About
          _SettingsSection(
            title: 'حول التطبيق',
            children: [
              _SettingsItem(
                icon: Icons.info_outlined,
                title: 'عن صَوْن',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'سياسة الخصوصية',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.description_outlined,
                title: 'الشروط والأحكام',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Version
          const Center(
            child: Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.surfaceVariant,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 24,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
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
