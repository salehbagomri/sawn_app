import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/document_model.dart';
import '../../../core/providers/document_provider.dart';

class DocumentDetailsScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentDetailsScreen({
    super.key,
    required this.documentId,
  });

  @override
  ConsumerState<DocumentDetailsScreen> createState() => _DocumentDetailsScreenState();
}

class _DocumentDetailsScreenState extends ConsumerState<DocumentDetailsScreen> {
  bool _isLoading = false;

  Future<void> _toggleFavorite(DocumentModel document) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(documentsNotifierProvider.notifier).toggleFavorite(document.id);
      ref.invalidate(documentByIdProvider(widget.documentId));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openInDrive(DocumentModel document) async {
    if (document.driveFileUrl == null) {
      _showError('لا يوجد رابط للملف');
      return;
    }

    final uri = Uri.parse(document.driveFileUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('لا يمكن فتح الرابط');
    }
  }

  Future<void> _deleteDocument(DocumentModel document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستند'),
        content: Text('هل أنت متأكد من حذف "${document.title}"؟\nسيتم حذف الملف من Google Drive أيضاً.'),
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

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final success = await ref.read(documentsNotifierProvider.notifier).deleteDocument(document.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المستند بنجاح'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        } else {
          _showError('حدث خطأ أثناء حذف المستند');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentAsync = ref.watch(documentByIdProvider(widget.documentId));

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: documentAsync.when(
        data: (document) {
          if (document == null) {
            return Center(
              child: Text(
                'المستند غير موجود',
                style: TextStyle(color: AppColors.getTextPrimary(context)),
              ),
            );
          }
          return _buildContent(document);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل المستند',
                style: TextStyle(color: AppColors.getTextPrimary(context)),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(documentByIdProvider(widget.documentId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(DocumentModel document) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // App Bar with Preview
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.getSurface(context),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      document.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: document.isFavorite ? AppColors.error : Colors.white,
                    ),
                  ),
                  onPressed: _isLoading ? null : () => _toggleFavorite(document),
                ),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.more_vert, color: Colors.white),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'open':
                        _openInDrive(document);
                        break;
                      case 'delete':
                        _deleteDocument(document);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (document.driveFileUrl != null)
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new, size: 20),
                            SizedBox(width: 12),
                            Text('فتح في Drive'),
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
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _DocumentPreviewHeader(document: document),
              ),
            ),

            // Document Info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            document.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StatusBadge(status: document.status),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Category
                    Row(
                      children: [
                        Icon(
                          document.category.icon,
                          size: 18,
                          color: AppColors.getTextSecondary(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          document.category.nameAr,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Info Cards
                    _InfoSection(document: document),

                    // Notes
                    if (document.notes != null && document.notes!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _NotesSection(notes: document.notes!),
                    ],

                    // Reminders
                    const SizedBox(height: 24),
                    _RemindersSection(documentId: document.id),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Loading Overlay
        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

class _DocumentPreviewHeader extends StatelessWidget {
  final DocumentModel document;

  const _DocumentPreviewHeader({required this.document});

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(document.category);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            categoryColor.withValues(alpha: 0.8),
            categoryColor.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                document.category.icon,
                size: 56,
                color: Colors.white,
              ),
            ),
            if (document.driveFileUrl != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'محفوظ في Google Drive',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.personal:
        return AppColors.categoryPersonal;
      case DocumentCategory.car:
        return AppColors.categoryCar;
      case DocumentCategory.work:
        return AppColors.categoryWork;
      case DocumentCategory.home:
        return AppColors.categoryHome;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final DocumentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, text, icon) = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String, IconData) _getStatusInfo() {
    switch (status) {
      case DocumentStatus.valid:
        return (AppColors.success, 'ساري', Icons.check_circle);
      case DocumentStatus.expiringSoon:
        return (AppColors.warning, 'ينتهي قريباً', Icons.warning_amber);
      case DocumentStatus.expired:
        return (AppColors.error, 'منتهي', Icons.error);
      case DocumentStatus.noExpiry:
        return (AppColors.info, 'بدون انتهاء', Icons.all_inclusive);
    }
  }
}

class _InfoSection extends StatelessWidget {
  final DocumentModel document;

  const _InfoSection({required this.document});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy', 'ar');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        children: [
          if (document.documentNumber != null)
            _InfoRow(
              icon: Icons.numbers,
              label: 'رقم المستند',
              value: document.documentNumber!,
            ),
          if (document.issueDate != null) ...[
            if (document.documentNumber != null) const Divider(height: 24),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'تاريخ الإصدار',
              value: dateFormat.format(document.issueDate!),
            ),
          ],
          if (document.expiryDate != null) ...[
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.event,
              label: 'تاريخ الانتهاء',
              value: dateFormat.format(document.expiryDate!),
              valueColor: document.status == DocumentStatus.expired
                  ? AppColors.error
                  : document.status == DocumentStatus.expiringSoon
                      ? AppColors.warning
                      : null,
            ),
            if (document.daysUntilExpiry != null) ...[
              const SizedBox(height: 8),
              _DaysRemainingIndicator(
                days: document.daysUntilExpiry!,
                status: document.status,
              ),
            ],
          ],
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.access_time,
            label: 'تاريخ الإضافة',
            value: dateFormat.format(document.createdAt),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.getTextTertiary(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextTertiary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.getTextPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DaysRemainingIndicator extends StatelessWidget {
  final int days;
  final DocumentStatus status;

  const _DaysRemainingIndicator({
    required this.days,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = status == DocumentStatus.expired
        ? AppColors.error
        : status == DocumentStatus.expiringSoon
            ? AppColors.warning
            : AppColors.success;

    final text = days < 0
        ? 'منتهي منذ ${-days} يوم'
        : days == 0
            ? 'ينتهي اليوم!'
            : 'باقي $days يوم';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            days <= 0 ? Icons.warning_amber : Icons.timer_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final String notes;

  const _NotesSection({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notes, size: 20, color: AppColors.getTextSecondary(context)),
            const SizedBox(width: 8),
            Text(
              'ملاحظات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getBorder(context)),
          ),
          child: Text(
            notes,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondary(context),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _RemindersSection extends ConsumerWidget {
  final String documentId;

  const _RemindersSection({required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(documentRemindersProvider(documentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications_outlined, size: 20, color: AppColors.getTextSecondary(context)),
            const SizedBox(width: 8),
            Text(
              'التذكيرات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        remindersAsync.when(
          data: (reminders) {
            if (reminders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Center(
                  child: Text(
                    'لا توجد تذكيرات',
                    style: TextStyle(
                      color: AppColors.getTextTertiary(context),
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: reminders.map((reminder) {
                final isPast = reminder.remindDate.isBefore(DateTime.now());
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPast
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPast
                          ? AppColors.warning.withValues(alpha: 0.3)
                          : AppColors.getBorder(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        reminder.isRead ? Icons.notifications_off : Icons.notifications_active,
                        size: 20,
                        color: isPast ? AppColors.warning : AppColors.getTextTertiary(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'قبل ${reminder.daysBefore} يوم',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            Text(
                              DateFormat('d/M/yyyy', 'ar').format(reminder.remindDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (reminder.isRead)
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: AppColors.success,
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Text(
            'حدث خطأ في تحميل التذكيرات',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}
