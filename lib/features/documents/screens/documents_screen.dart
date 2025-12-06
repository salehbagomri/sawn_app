import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/document_model.dart';
import '../../../core/providers/document_provider.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  final bool focusSearch;

  const DocumentsScreen({
    super.key,
    this.focusSearch = false,
  });

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _isSearching = true);
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedStatus = ref.watch(selectedStatusProvider);
    final documentsAsync = ref.watch(filteredDocumentsProvider);

    final hasActiveFilters = selectedCategory != null || selectedStatus != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  hintText: 'ابحث في المستندات...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: _onSearchChanged,
              )
            : const Text('مستنداتي'),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => _isSearching = false);
                  _clearSearch();
                },
              )
            : null,
        actions: [
          if (!_isSearching)
            IconButton(
              onPressed: () {
                setState(() => _isSearching = true);
                _searchFocusNode.requestFocus();
              },
              icon: const Icon(Icons.search),
            ),
          if (_isSearching && searchQuery.isNotEmpty)
            IconButton(
              onPressed: _clearSearch,
              icon: const Icon(Icons.close),
            ),
          Stack(
            children: [
              IconButton(
                onPressed: _showFilterSheet,
                icon: const Icon(Icons.filter_list),
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters chips
          if (hasActiveFilters)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (selectedCategory != null)
                    _FilterChip(
                      label: selectedCategory.nameAr,
                      icon: selectedCategory.icon,
                      onRemove: () => ref.read(selectedCategoryProvider.notifier).state = null,
                    ),
                  if (selectedStatus != null)
                    _FilterChip(
                      label: _getStatusName(selectedStatus),
                      icon: _getStatusIcon(selectedStatus),
                      onRemove: () => ref.read(selectedStatusProvider.notifier).state = null,
                    ),
                ],
              ),
            ),

          // Documents list
          Expanded(
            child: documentsAsync.when(
              data: (documents) {
                // Apply local filters
                var filtered = documents;
                if (selectedCategory != null) {
                  filtered = filtered.where((d) => d.category == selectedCategory).toList();
                }
                if (selectedStatus != null) {
                  filtered = filtered.where((d) => d.status == selectedStatus).toList();
                }

                if (filtered.isEmpty) {
                  return _EmptyState(
                    hasSearch: searchQuery.isNotEmpty,
                    hasFilters: hasActiveFilters,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(filteredDocumentsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      return _DocumentListItem(
                        document: doc,
                        onTap: () => context.push('/document/${doc.id}'),
                        onFavoriteToggle: () async {
                          await ref.read(documentsNotifierProvider.notifier).toggleFavorite(doc.id);
                          ref.invalidate(filteredDocumentsProvider);
                        },
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
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    const Text('حدث خطأ في تحميل المستندات'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(filteredDocumentsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusName(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.valid:
        return 'ساري';
      case DocumentStatus.expiringSoon:
        return 'ينتهي قريباً';
      case DocumentStatus.expired:
        return 'منتهي';
      case DocumentStatus.noExpiry:
        return 'بدون انتهاء';
    }
  }

  IconData _getStatusIcon(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.valid:
        return Icons.check_circle;
      case DocumentStatus.expiringSoon:
        return Icons.warning_amber;
      case DocumentStatus.expired:
        return Icons.error;
      case DocumentStatus.noExpiry:
        return Icons.all_inclusive;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedStatus = ref.watch(selectedStatusProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'فلترة المستندات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (selectedCategory != null || selectedStatus != null)
                    TextButton(
                      onPressed: () {
                        ref.read(selectedCategoryProvider.notifier).state = null;
                        ref.read(selectedStatusProvider.notifier).state = null;
                      },
                      child: const Text('مسح الكل'),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Filter
              const Text(
                'التصنيف',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DocumentCategory.values.map((category) {
                  final isSelected = category == selectedCategory;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 18,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(category.nameAr),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(selectedCategoryProvider.notifier).state =
                          selected ? category : null;
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Status Filter
              const Text(
                'الحالة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DocumentStatus.values.map((status) {
                  final isSelected = status == selectedStatus;
                  return ChoiceChip(
                    label: Text(_getStatusName(status)),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(selectedStatusProvider.notifier).state =
                          selected ? status : null;
                    },
                    selectedColor: _getStatusColor(status),
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Apply Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('تطبيق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusName(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.valid:
        return 'ساري';
      case DocumentStatus.expiringSoon:
        return 'ينتهي قريباً';
      case DocumentStatus.expired:
        return 'منتهي';
      case DocumentStatus.noExpiry:
        return 'بدون انتهاء';
    }
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.valid:
        return AppColors.success;
      case DocumentStatus.expiringSoon:
        return AppColors.warning;
      case DocumentStatus.expired:
        return AppColors.error;
      case DocumentStatus.noExpiry:
        return AppColors.info;
    }
  }
}

class _DocumentListItem extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _DocumentListItem({
    required this.document,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(document.category);
    final statusInfo = _getStatusInfo(document.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  document.category.icon,
                  color: categoryColor,
                  size: 28,
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
                        Expanded(
                          child: Text(
                            document.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusInfo.$1.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusInfo.$3, size: 12, color: statusInfo.$1),
                              const SizedBox(width: 4),
                              Text(
                                statusInfo.$2,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusInfo.$1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          document.category.icon,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          document.category.nameAr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (document.documentNumber != null) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.numbers,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              document.documentNumber!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (document.expiryDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 14,
                            color: document.status == DocumentStatus.expired
                                ? AppColors.error
                                : document.status == DocumentStatus.expiringSoon
                                    ? AppColors.warning
                                    : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ينتهي: ${DateFormat('d/M/yyyy', 'ar').format(document.expiryDate!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: document.status == DocumentStatus.expired
                                  ? AppColors.error
                                  : document.status == DocumentStatus.expiringSoon
                                      ? AppColors.warning
                                      : AppColors.textTertiary,
                              fontWeight: document.status != DocumentStatus.valid
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (document.daysUntilExpiry != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              document.daysUntilExpiry! < 0
                                  ? '(منتهي)'
                                  : document.daysUntilExpiry == 0
                                      ? '(اليوم!)'
                                      : '(${document.daysUntilExpiry} يوم)',
                              style: TextStyle(
                                fontSize: 11,
                                color: document.status == DocumentStatus.expired
                                    ? AppColors.error
                                    : document.status == DocumentStatus.expiringSoon
                                        ? AppColors.warning
                                        : AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Favorite button
              IconButton(
                onPressed: onFavoriteToggle,
                icon: Icon(
                  document.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: document.isFavorite ? AppColors.error : AppColors.textTertiary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
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

  (Color, String, IconData) _getStatusInfo(DocumentStatus status) {
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

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final bool hasFilters;

  const _EmptyState({
    required this.hasSearch,
    required this.hasFilters,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    if (hasSearch) {
      message = 'لم يتم العثور على نتائج للبحث';
      icon = Icons.search_off;
    } else if (hasFilters) {
      message = 'لا توجد مستندات تطابق الفلاتر المحددة';
      icon = Icons.filter_alt_off;
    } else {
      message = 'لا توجد مستندات بعد';
      icon = Icons.folder_open;
    }

    return Center(
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
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!hasSearch && !hasFilters) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/add-document'),
              icon: const Icon(Icons.add),
              label: const Text('إضافة مستند'),
            ),
          ],
        ],
      ),
    );
  }
}
