import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/document_model.dart';
import '../../../core/models/reminder_model.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/services/ocr_service.dart';
import 'add_document_screen.dart';

class DocumentFormScreen extends ConsumerStatefulWidget {
  final File file;
  final DocumentSourceType sourceType;
  final File? additionalFile; // For back side of document

  const DocumentFormScreen({
    super.key,
    required this.file,
    required this.sourceType,
    this.additionalFile,
  });

  @override
  ConsumerState<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends ConsumerState<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _notesController = TextEditingController();

  DocumentCategory _selectedCategory = DocumentCategory.personal;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  List<ReminderOption> _reminderOptions = ReminderOption.defaultOptions;
  bool _isSaving = false;
  bool _isExtractingText = false;

  @override
  void dispose() {
    _titleController.dispose();
    _documentNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isExpiry) async {
    final now = DateTime.now();
    final initialDate = isExpiry
        ? (_expiryDate ?? now.add(const Duration(days: 365)))
        : (_issueDate ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isExpiry ? now : DateTime(2000),
      lastDate: isExpiry ? DateTime(2100) : now,
      locale: const Locale('ar'),
    );

    if (date != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = date;
        } else {
          _issueDate = date;
        }
      });
    }
  }

  void _toggleReminder(int index) {
    setState(() {
      _reminderOptions = _reminderOptions.asMap().entries.map((entry) {
        if (entry.key == index) {
          return entry.value.copyWith(isSelected: !entry.value.isSelected);
        }
        return entry.value;
      }).toList();
    });
  }

  /// Extract text from image using OCR
  Future<void> _extractText() async {
    // Only works for images, not PDFs
    if (widget.sourceType == DocumentSourceType.pdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('استخراج النص غير متاح لملفات PDF'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isExtractingText = true);

    try {
      final ocrService = OcrService();
      final result = await ocrService.extractText(widget.file);

      setState(() => _isExtractingText = false);

      if (result.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على نص في الصورة'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Show dialog with extracted data
      if (mounted) {
        _showOcrResultDialog(result);
      }
    } catch (e) {
      debugPrint('Error extracting text: $e');
      setState(() => _isExtractingText = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء استخراج النص'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Show dialog with OCR results
  void _showOcrResultDialog(OcrResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.document_scanner, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'النص المستخرج',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Extracted fields
            if (result.hasExtractedFields) ...[
              const Text(
                'البيانات المستخرجة:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ...result.extractedFields.entries.map((entry) {
                return _buildExtractedField(
                  _getFieldLabel(entry.key),
                  entry.value,
                  () => _applyField(entry.key, entry.value),
                );
              }),
              const Divider(height: 24),
            ],

            // Full text (collapsed)
            ExpansionTile(
              title: const Text('النص الكامل'),
              tilePadding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.fullText.isEmpty ? 'لا يوجد نص' : result.fullText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Apply all button
            if (result.hasExtractedFields)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _applyAllFields(result);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('تطبيق جميع البيانات'),
                ),
              ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedField(String label, String value, VoidCallback onApply) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('تطبيق'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getFieldLabel(String key) {
    switch (key) {
      case 'documentNumber':
        return 'رقم المستند';
      case 'expiryDate':
        return 'تاريخ الانتهاء';
      case 'issueDate':
        return 'تاريخ الإصدار';
      case 'name':
        return 'الاسم';
      case 'idNumber':
        return 'رقم الهوية';
      default:
        return key;
    }
  }

  void _applyField(String key, String value) {
    setState(() {
      switch (key) {
        case 'documentNumber':
        case 'idNumber':
          _documentNumberController.text = value;
          break;
        case 'expiryDate':
          _expiryDate = _parseDate(value);
          break;
        case 'issueDate':
          _issueDate = _parseDate(value);
          break;
        case 'name':
          if (_titleController.text.isEmpty) {
            _titleController.text = value;
          }
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تطبيق: ${_getFieldLabel(key)}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _applyAllFields(OcrResult result) {
    setState(() {
      for (final entry in result.extractedFields.entries) {
        switch (entry.key) {
          case 'documentNumber':
          case 'idNumber':
            if (_documentNumberController.text.isEmpty) {
              _documentNumberController.text = entry.value;
            }
            break;
          case 'expiryDate':
            _expiryDate ??= _parseDate(entry.value);
            break;
          case 'issueDate':
            _issueDate ??= _parseDate(entry.value);
            break;
          case 'name':
            if (_titleController.text.isEmpty) {
              _titleController.text = entry.value;
            }
            break;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تطبيق جميع البيانات المستخرجة'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  DateTime? _parseDate(String dateStr) {
    try {
      // Try various date formats
      final formats = [
        'yyyy/MM/dd',
        'dd/MM/yyyy',
        'yyyy-MM-dd',
        'dd-MM-yyyy',
        'yyyy.MM.dd',
        'dd.MM.yyyy',
      ];

      for (final format in formats) {
        try {
          return DateFormat(format).parse(dateStr);
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      debugPrint('=== Starting document save ===');
      debugPrint('Title: ${_titleController.text.trim()}');
      debugPrint('Category: ${_selectedCategory.nameEn}');
      debugPrint('File path: ${widget.file.path}');
      debugPrint('File exists: ${widget.file.existsSync()}');

      final selectedReminders = _reminderOptions
          .where((r) => r.isSelected)
          .map((r) => r.daysBefore)
          .toList();

      debugPrint('Selected reminders: $selectedReminders');
      debugPrint('Expiry date: $_expiryDate');

      final document = await ref.read(documentsNotifierProvider.notifier).createDocument(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        documentNumber: _documentNumberController.text.trim().isNotEmpty
            ? _documentNumberController.text.trim()
            : null,
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        file: widget.file,
        reminderDays: _expiryDate != null ? selectedReminders : null,
      );

      debugPrint('Document result: ${document != null ? "SUCCESS" : "NULL"}');

      if (document != null && mounted) {
        debugPrint('Document saved successfully with ID: ${document.id}');
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ المستند بنجاح'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate back to home
        context.go('/main/home');
      } else {
        debugPrint('Document save returned null - showing error');
        _showError('حدث خطأ أثناء حفظ المستند');
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in _saveDocument: $e');
      debugPrint('Stack trace: $stackTrace');
      _showError('حدث خطأ غير متوقع: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('بيانات المستند'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Document Preview with OCR button
            _DocumentPreview(
              file: widget.file,
              sourceType: widget.sourceType,
              isExtractingText: _isExtractingText,
              onExtractText: _extractText,
            ),

            // Back side preview (if available)
            if (widget.additionalFile != null) ...[
              const SizedBox(height: 16),
              const Text(
                'الجهة الخلفية:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    widget.additionalFile!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Title Field
            _buildLabel('عنوان المستند', isRequired: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(
                hint: 'مثال: بطاقة الهوية الوطنية',
                prefixIcon: Icons.title,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال عنوان المستند';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            // Category Selection
            _buildLabel('التصنيف', isRequired: true),
            const SizedBox(height: 8),
            _CategorySelector(
              selected: _selectedCategory,
              onChanged: (cat) => setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 20),

            // Document Number
            _buildLabel('رقم المستند'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _documentNumberController,
              decoration: _inputDecoration(
                hint: 'مثال: 1234567890',
                prefixIcon: Icons.numbers,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            // Dates Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('تاريخ الإصدار'),
                      const SizedBox(height: 8),
                      _DateField(
                        date: _issueDate,
                        hint: 'اختر التاريخ',
                        onTap: () => _selectDate(false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('تاريخ الانتهاء'),
                      const SizedBox(height: 8),
                      _DateField(
                        date: _expiryDate,
                        hint: 'اختر التاريخ',
                        onTap: () => _selectDate(true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Reminders Section (only show if expiry date is set)
            if (_expiryDate != null) ...[
              _buildLabel('التذكيرات'),
              const SizedBox(height: 8),
              const Text(
                'سنذكرك قبل انتهاء المستند',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reminderOptions.asMap().entries.map((entry) {
                  final option = entry.value;
                  return FilterChip(
                    label: Text(option.labelAr),
                    selected: option.isSelected,
                    onSelected: (_) => _toggleReminder(entry.key),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: option.isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Notes Field
            _buildLabel('ملاحظات'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: _inputDecoration(
                hint: 'أضف ملاحظات إضافية...',
                prefixIcon: Icons.notes,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveDocument,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'حفظ المستند',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: AppColors.textTertiary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  final File file;
  final DocumentSourceType sourceType;
  final bool isExtractingText;
  final VoidCallback onExtractText;

  const _DocumentPreview({
    required this.file,
    required this.sourceType,
    required this.isExtractingText,
    required this.onExtractText,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = sourceType == DocumentSourceType.pdf;

    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isPdf
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 64,
                          color: AppColors.error.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          file.path.split('/').last,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                : Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
          ),
        ),
        // OCR Button (only for images)
        if (!isPdf) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isExtractingText ? null : onExtractText,
              icon: isExtractingText
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner_outlined, size: 20),
              label: Text(
                isExtractingText ? 'جاري استخراج النص...' : 'استخراج النص تلقائياً',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final DocumentCategory selected;
  final ValueChanged<DocumentCategory> onChanged;

  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DocumentCategory.values.map((category) {
        final isSelected = category == selected;
        final color = _getCategoryColor(category);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: category == DocumentCategory.values.last ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => onChanged(category),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      category.icon,
                      color: isSelected ? color : AppColors.textTertiary,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.nameAr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? color : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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

class _DateField extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;

  const _DateField({
    required this.date,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: date != null ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('d/M/yyyy', 'ar').format(date!)
                    : hint,
                style: TextStyle(
                  fontSize: 14,
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
