import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/drive_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/google_drive_service.dart';
import '../../../core/services/offline_storage_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoBackupEnabled = true;
  bool _isSigningOut = false;
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadAutoBackupSetting();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck && isDeviceSupported;
        });
      }
    } catch (e) {
      // Biometrics not available
    }
  }

  Future<void> _loadAutoBackupSetting() async {
    await _offlineStorage.initialize();
    if (mounted) {
      setState(() {
        _autoBackupEnabled = _offlineStorage.autoBackupEnabled;
      });
    }
  }

  Future<void> _setAutoBackupEnabled(bool value) async {
    setState(() => _autoBackupEnabled = value);
    await _offlineStorage.setAutoBackupEnabled(value);
  }

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

  void _showStorageInfo() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
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

  void _showDriveInfo() {
    final driveStatus = ref.read(driveStatusProvider);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_to_drive,
                    color: Color(0xFF4285F4),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Drive',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            driveStatus.isConnected
                                ? Icons.check_circle
                                : Icons.error,
                            size: 16,
                            color: driveStatus.isConnected
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            driveStatus.isConnected ? 'متصل' : 'غير متصل',
                            style: TextStyle(
                              fontSize: 14,
                              color: driveStatus.isConnected
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (driveStatus.isConnected) ...[
              ListTile(
                leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                title: const Text('البريد الإلكتروني'),
                subtitle: Text(driveStatus.userEmail ?? '-'),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.folder_outlined, color: AppColors.primary),
                title: const Text('مجلد النسخ الاحتياطي'),
                subtitle: const Text('Sawn Documents'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Text(
                'يتم حفظ جميع مستنداتك بشكل آمن في Google Drive',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextTertiary(context),
                ),
              ),
            ] else ...[
              Text(
                'لم يتم الاتصال بـ Google Drive. يرجى تسجيل الدخول مرة أخرى.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ],
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تطبيق صَوْن لحفظ وإدارة مستنداتك',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '• حفظ آمن للمستندات في Google Drive\n'
              '• تذكيرات تلقائية قبل انتهاء المستندات\n'
              '• تنظيم المستندات حسب التصنيف\n'
              '• دعم كامل للغة العربية',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
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

  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse(AppConstants.privacyPolicyUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح الرابط'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openAppRating() async {
    final url = Uri.parse(
      Platform.isIOS ? AppConstants.appStoreUrl : AppConstants.playStoreUrl,
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح المتجر'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final googleUserInfo = ref.watch(googleUserInfoProvider);

    // Try Google account name first, then Supabase metadata, then fallback
    final userName = googleUserInfo.displayName ??
        user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        'مستخدم';

    // Try Google email first, then Supabase email
    final userEmail = googleUserInfo.email ?? user?.email ?? '';

    // Try Google photo first, then Supabase metadata
    final avatarUrl = googleUserInfo.photoUrl ?? user?.userMetadata?['avatar_url'] as String?;

    final stats = ref.watch(documentStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
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

              // App Settings
              _SettingsSection(
                title: 'التطبيق',
                children: [
                  _SettingsItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'الوضع الليلي',
                    trailing: Switch(
                      value: ref.watch(themeModeProvider) == ThemeMode.dark,
                      onChanged: (value) {
                        ref.read(themeModeProvider.notifier).setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggleDarkMode();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Security & Notifications
              _SettingsSection(
                title: 'الأمان والإشعارات',
                children: [
                  if (_canCheckBiometrics)
                    _SettingsItem(
                      icon: Icons.fingerprint,
                      title: 'قفل التطبيق بالبصمة',
                      subtitle: 'طلب البصمة عند فتح التطبيق',
                      trailing: Switch(
                        value: ref.watch(appLockEnabledProvider),
                        onChanged: (value) async {
                          if (value) {
                            // Verify biometric before enabling
                            try {
                              final authenticated = await _localAuth.authenticate(
                                localizedReason: 'تأكيد هويتك لتفعيل قفل التطبيق',
                                authMessages: const <AuthMessages>[
                                  AndroidAuthMessages(
                                    signInTitle: 'المصادقة مطلوبة',
                                    biometricHint: 'تحقق من هويتك',
                                    biometricNotRecognized: 'لم يتم التعرف. حاول مرة أخرى.',
                                    biometricSuccess: 'تم التحقق بنجاح',
                                    cancelButton: 'إلغاء',
                                    deviceCredentialsRequiredTitle: 'مطلوب رمز القفل',
                                    deviceCredentialsSetupDescription: 'يرجى إعداد رمز قفل الجهاز',
                                    goToSettingsButton: 'الإعدادات',
                                    goToSettingsDescription: 'لم يتم إعداد المصادقة البيومترية.',
                                  ),
                                  IOSAuthMessages(
                                    cancelButton: 'إلغاء',
                                    goToSettingsButton: 'الإعدادات',
                                    goToSettingsDescription: 'يرجى إعداد المصادقة البيومترية.',
                                    lockOut: 'يرجى إعادة تفعيل المصادقة البيومترية',
                                  ),
                                ],
                                options: const AuthenticationOptions(
                                  stickyAuth: true,
                                  biometricOnly: false, // Allow PIN/Pattern as fallback
                                ),
                              );
                              if (authenticated) {
                                ref.read(appLockEnabledProvider.notifier).setAppLockEnabled(true);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم تفعيل قفل التطبيق'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('Biometric auth error: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('فشل التحقق: ${e.toString()}'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          } else {
                            ref.read(appLockEnabledProvider.notifier).setAppLockEnabled(false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم إلغاء قفل التطبيق'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                        activeColor: AppColors.primary,
                      ),
                      onTap: () {},
                    ),
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'الإشعارات',
                    subtitle: 'تذكيرات انتهاء المستندات',
                    trailing: Switch(
                      value: ref.watch(notificationsEnabledProvider),
                      onChanged: (value) {
                        ref.read(notificationsEnabledProvider.notifier).setNotificationsEnabled(value);
                      },
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      ref.read(notificationsEnabledProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Backup & Storage
              _SettingsSection(
                title: 'النسخ الاحتياطي والتخزين',
                children: [
                  Builder(
                    builder: (context) {
                      final driveStatus = ref.watch(driveStatusProvider);
                      return _SettingsItem(
                        icon: Icons.add_to_drive,
                        iconColor: const Color(0xFF4285F4),
                        title: 'Google Drive',
                        subtitle: driveStatus.isConnected ? 'متصل' : 'غير متصل',
                        onTap: _showDriveInfo,
                      );
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.cloud_upload_outlined,
                    title: 'النسخ الاحتياطي التلقائي',
                    trailing: Switch(
                      value: _autoBackupEnabled,
                      onChanged: (value) => _setAutoBackupEnabled(value),
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.primary,
                    ),
                    onTap: () => _setAutoBackupEnabled(!_autoBackupEnabled),
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
                    onTap: _openPrivacyPolicy,
                  ),
                  _SettingsItem(
                    icon: Icons.star_outline,
                    title: 'قيم التطبيق',
                    onTap: _openAppRating,
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
              Center(
                child: Text(
                  'الإصدار 1.0.0',
                  style: TextStyle(
                    color: AppColors.getTextTertiary(context),
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextTertiary(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getSurfaceVariant(context),
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
              color: iconColor ?? AppColors.getTextSecondary(context),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextTertiary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_left,
                  color: AppColors.getTextTertiary(context),
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}
