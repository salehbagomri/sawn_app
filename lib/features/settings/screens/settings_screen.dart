import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/services/google_drive_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/offline_storage_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoBackupEnabled = true;
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSigningOut = true);
      try {
        // Sign out from Google Drive
        final driveService = GoogleDriveService();
        await driveService.signOut();

        // Sign out from Supabase
        await Supabase.instance.client.auth.signOut();

        if (mounted) {
          context.go(AppRoutes.login);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ أثناء تسجيل الخروج'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSigningOut = false);
      }
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعدادات الإشعارات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.notifications_active, color: AppColors.primary),
              title: const Text('اختبار الإشعارات'),
              subtitle: const Text('إرسال إشعار تجريبي'),
              onTap: () async {
                Navigator.pop(context);
                // Request permissions first
                final hasPermission = await NotificationService().requestPermissions();
                if (!hasPermission) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى السماح بالإشعارات من إعدادات الجهاز'),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                await NotificationService().showTestNotification();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال إشعار تجريبي - تحقق من شريط الإشعارات'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.secondary),
              title: const Text('الإشعارات المجدولة'),
              subtitle: FutureBuilder<int>(
                future: NotificationService().getPendingNotificationsCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Text('$count إشعار مجدول');
                },
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getSyncStatusText() {
    final syncService = SyncService();
    final lastSync = syncService.lastSyncTime;
    final pendingCount = syncService.pendingSyncCount;

    if (pendingCount > 0) {
      return '$pendingCount عنصر بانتظار المزامنة';
    } else if (lastSync != null) {
      final diff = DateTime.now().difference(lastSync);
      if (diff.inMinutes < 1) {
        return 'تمت المزامنة الآن';
      } else if (diff.inMinutes < 60) {
        return 'آخر مزامنة منذ ${diff.inMinutes} دقيقة';
      } else if (diff.inHours < 24) {
        return 'آخر مزامنة منذ ${diff.inHours} ساعة';
      } else {
        return 'آخر مزامنة منذ ${diff.inDays} يوم';
      }
    }
    return 'لم تتم المزامنة بعد';
  }

  void _showSyncSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المزامنة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.sync, color: AppColors.primary),
              title: const Text('مزامنة الآن'),
              subtitle: Text(_getSyncStatusText()),
              onTap: () async {
                Navigator.pop(context);
                final result = await SyncService().syncPendingChanges();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(result.success ? 'تمت المزامنة بنجاح' : 'فشلت المزامنة'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                setState(() {}); // Refresh UI
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.secondary),
              title: const Text('تحديث ذاكرة التخزين المؤقت'),
              subtitle: const Text('جلب أحدث البيانات من الخادم'),
              onTap: () async {
                Navigator.pop(context);
                await SyncService().refreshDocumentsCache();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث ذاكرة التخزين المؤقت'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showStorageInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'التخزين المحلي',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            FutureBuilder<int>(
              future: OfflineStorageService().getCacheSize(),
              builder: (context, snapshot) {
                final sizeBytes = snapshot.data ?? 0;
                final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
                return ListTile(
                  leading: const Icon(Icons.folder, color: AppColors.primary),
                  title: const Text('حجم ذاكرة التخزين المؤقت'),
                  subtitle: Text('$sizeMB ميجابايت'),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('مسح ذاكرة التخزين المؤقت'),
              subtitle: const Text('حذف جميع الملفات المخزنة محلياً'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: this.context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('مسح ذاكرة التخزين المؤقت'),
                    content: const Text('هل أنت متأكد؟ سيتم حذف جميع الملفات المخزنة محلياً.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('مسح'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await OfflineStorageService().clearFileCache();
                  await OfflineStorageService().clearDocumentsCache();
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('تم مسح ذاكرة التخزين المؤقت'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield, color: AppColors.primary),
            SizedBox(width: 12),
            Text('صَوْن'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تطبيق صَوْن لحفظ وإدارة مستنداتك',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '• حفظ آمن للمستندات في Google Drive\n'
              '• تذكيرات تلقائية قبل انتهاء المستندات\n'
              '• تنظيم المستندات حسب التصنيف\n'
              '• دعم كامل للغة العربية',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? 'مستخدم';
    final userEmail = user?.email ?? '';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final stats = ref.watch(documentStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // User Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: ClipOval(
                            child: avatarUrl != null
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  )
                                : Container(
                                    color: Colors.white24,
                                    child: const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Stats Row
                    stats.when(
                      data: (data) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            value: '${data['total'] ?? 0}',
                            label: 'مستند',
                          ),
                          _StatItem(
                            value: '${data['favorites'] ?? 0}',
                            label: 'مفضلة',
                          ),
                          _StatItem(
                            value: '${data['expiringSoon'] ?? 0}',
                            label: 'ينتهي قريباً',
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(height: 40),
                      error: (_, __) => const SizedBox(height: 40),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Account Section
              _SettingsSection(
                title: 'الحساب',
                children: [
                  _SettingsItem(
                    icon: Icons.lock_outlined,
                    title: 'تغيير الرمز السري',
                    onTap: () {
                      // TODO: Navigate to PIN change
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.fingerprint,
                    title: 'البصمة / Face ID',
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: (value) {
                        setState(() => _biometricEnabled = value);
                      },
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      setState(() => _biometricEnabled = !_biometricEnabled);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // App Settings
              _SettingsSection(
                title: 'التطبيق',
                children: [
                  _SettingsItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'الوضع الليلي',
                    trailing: Switch(
                      value: _darkModeEnabled,
                      onChanged: (value) {
                        setState(() => _darkModeEnabled = value);
                        // TODO: Implement dark mode
                      },
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      setState(() => _darkModeEnabled = !_darkModeEnabled);
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'إعدادات الإشعارات',
                    onTap: () => _showNotificationSettings(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Backup & Storage
              _SettingsSection(
                title: 'النسخ الاحتياطي والتخزين',
                children: [
                  _SettingsItem(
                    icon: Icons.add_to_drive,
                    iconColor: const Color(0xFF4285F4),
                    title: 'Google Drive',
                    subtitle: 'متصل',
                    onTap: () {
                      // TODO: Show Drive info
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.cloud_upload_outlined,
                    title: 'النسخ الاحتياطي التلقائي',
                    trailing: Switch(
                      value: _autoBackupEnabled,
                      onChanged: (value) {
                        setState(() => _autoBackupEnabled = value);
                      },
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.primary,
                    ),
                    onTap: () {
                      setState(() => _autoBackupEnabled = !_autoBackupEnabled);
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.sync,
                    title: 'المزامنة',
                    subtitle: _getSyncStatusText(),
                    onTap: _showSyncSettings,
                  ),
                  _SettingsItem(
                    icon: Icons.storage_outlined,
                    title: 'مساحة التخزين المحلي',
                    subtitle: 'إدارة الملفات المخزنة',
                    onTap: _showStorageInfo,
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
                    onTap: _showAboutDialog,
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'سياسة الخصوصية',
                    onTap: () {
                      // TODO: Open privacy policy
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.star_outline,
                    title: 'قيم التطبيق',
                    onTap: () {
                      // TODO: Open store rating
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSigningOut ? null : _signOut,
                  icon: _isSigningOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        )
                      : const Icon(Icons.logout, color: AppColors.error),
                  label: Text(
                    _isSigningOut ? 'جاري الخروج...' : 'تسجيل الخروج',
                    style: const TextStyle(color: AppColors.error),
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
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
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
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    this.iconColor,
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
              color: iconColor ?? AppColors.textSecondary,
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
