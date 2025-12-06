import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/reminder_model.dart';
import '../../../core/providers/document_provider.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead(String reminderId) async {
    final service = ref.read(documentServiceProvider);
    await service.markReminderRead(reminderId);
    ref.invalidate(remindersProvider);
    ref.invalidate(dueRemindersProvider);
    ref.invalidate(unreadRemindersCountProvider);
  }

  Future<void> _deleteReminder(String reminderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التذكير'),
        content: const Text('هل أنت متأكد من حذف هذا التذكير؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(documentServiceProvider);
      await service.deleteReminder(reminderId);
      ref.invalidate(remindersProvider);
      ref.invalidate(dueRemindersProvider);
      ref.invalidate(unreadRemindersCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف التذكير'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التنبيهات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'المستحقة'),
            Tab(text: 'جميع التذكيرات'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Due Reminders Tab
          _DueRemindersTab(
            onMarkAsRead: _markAsRead,
            onDelete: _deleteReminder,
          ),
          // All Reminders Tab
          _AllRemindersTab(
            onMarkAsRead: _markAsRead,
            onDelete: _deleteReminder,
          ),
        ],
      ),
    );
  }
}

class _DueRemindersTab extends ConsumerWidget {
  final Function(String) onMarkAsRead;
  final Function(String) onDelete;

  const _DueRemindersTab({
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(dueRemindersProvider);

    return remindersAsync.when(
      data: (reminders) {
        if (reminders.isEmpty) {
          return const _EmptyState(
            icon: Icons.notifications_off,
            message: 'لا توجد تذكيرات مستحقة',
            subtitle: 'ستظهر هنا التذكيرات التي حان موعدها',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dueRemindersProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return _ReminderCard(
                reminder: reminder,
                onTap: () {
                  context.push('/document/${reminder.documentId}');
                },
                onMarkAsRead: () => onMarkAsRead(reminder.id),
                onDelete: () => onDelete(reminder.id),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('حدث خطأ في تحميل التذكيرات'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(dueRemindersProvider),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllRemindersTab extends ConsumerWidget {
  final Function(String) onMarkAsRead;
  final Function(String) onDelete;

  const _AllRemindersTab({
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);

    return remindersAsync.when(
      data: (reminders) {
        if (reminders.isEmpty) {
          return const _EmptyState(
            icon: Icons.notifications_none,
            message: 'لا توجد تذكيرات',
            subtitle: 'أضف تاريخ انتهاء للمستندات لتفعيل التذكيرات',
          );
        }

        // Group by month
        final groupedReminders = <String, List<ReminderModel>>{};
        for (final reminder in reminders) {
          final monthKey = DateFormat('MMMM yyyy', 'ar').format(reminder.remindDate);
          groupedReminders.putIfAbsent(monthKey, () => []).add(reminder);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(remindersProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedReminders.length,
            itemBuilder: (context, index) {
              final month = groupedReminders.keys.elementAt(index);
              final monthReminders = groupedReminders[month]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      month,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  ...monthReminders.map((reminder) => _ReminderCard(
                        reminder: reminder,
                        onTap: () {
                          context.push('/document/${reminder.documentId}');
                        },
                        onMarkAsRead: () => onMarkAsRead(reminder.id),
                        onDelete: () => onDelete(reminder.id),
                      )),
                ],
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('حدث خطأ في تحميل التذكيرات'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(remindersProvider),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = reminder.remindDate.isBefore(DateTime.now());
    final isToday = _isToday(reminder.remindDate);

    Color cardColor;
    Color accentColor;
    IconData statusIcon;

    if (reminder.isRead) {
      cardColor = AppColors.surface;
      accentColor = AppColors.textTertiary;
      statusIcon = Icons.check_circle;
    } else if (isPast) {
      cardColor = AppColors.error.withValues(alpha: 0.05);
      accentColor = AppColors.error;
      statusIcon = Icons.warning_amber;
    } else if (isToday) {
      cardColor = AppColors.warning.withValues(alpha: 0.05);
      accentColor = AppColors.warning;
      statusIcon = Icons.notifications_active;
    } else {
      cardColor = AppColors.surface;
      accentColor = AppColors.info;
      statusIcon = Icons.notifications;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: reminder.isRead
                  ? AppColors.border
                  : accentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Status Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!reminder.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            reminder.documentTitle ?? 'مستند',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  reminder.isRead ? FontWeight.normal : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(reminder.documentCategory),
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reminder.documentCategory ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'قبل ${reminder.daysBefore} يوم',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDateLabel(reminder.remindDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textTertiary),
                onSelected: (value) {
                  switch (value) {
                    case 'read':
                      onMarkAsRead();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!reminder.isRead)
                    const PopupMenuItem(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(Icons.done, size: 20),
                          SizedBox(width: 12),
                          Text('تم القراءة'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('حذف', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = DateTime(date.year, date.month, date.day);
    final difference = reminderDate.difference(today).inDays;

    if (difference == 0) {
      return 'اليوم';
    } else if (difference == 1) {
      return 'غداً';
    } else if (difference == -1) {
      return 'أمس';
    } else if (difference < 0) {
      return 'منذ ${-difference} يوم';
    } else if (difference <= 7) {
      return 'بعد $difference أيام';
    } else {
      return DateFormat('d MMMM yyyy', 'ar').format(date);
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'شخصي':
        return Icons.person_outlined;
      case 'السيارة':
        return Icons.directions_car_outlined;
      case 'العمل':
        return Icons.work_outlined;
      case 'السكن':
        return Icons.home_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
