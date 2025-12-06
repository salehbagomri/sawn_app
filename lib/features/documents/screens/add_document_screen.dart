import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import 'document_form_screen.dart';

class AddDocumentScreen extends ConsumerStatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  ConsumerState<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends ConsumerState<AddDocumentScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _openCamera() async {
    setState(() => _isLoading = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null && mounted) {
        // Ask if user wants to scan the back side
        final scanBack = await _showScanBackDialog();

        File? backFile;
        if (scanBack == true) {
          final XFile? backPhoto = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
            preferredCameraDevice: CameraDevice.rear,
          );
          if (backPhoto != null) {
            backFile = File(backPhoto.path);
          }
        }

        if (mounted) {
          _navigateToForm(File(photo.path), DocumentSourceType.camera, additionalFile: backFile);
        }
      }
    } catch (e) {
      _showError('حدث خطأ أثناء فتح الكاميرا');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showScanBackDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصوير الظهر'),
        content: const Text('هل تريد تصوير الجهة الخلفية للمستند أيضاً؟\n(مثل ظهر بطاقة الهوية)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا، متابعة'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، تصوير الظهر'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGallery() async {
    setState(() => _isLoading = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        _navigateToForm(File(image.path), DocumentSourceType.gallery);
      }
    } catch (e) {
      _showError('حدث خطأ أثناء فتح المعرض');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openFilePicker() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        final file = File(result.files.first.path!);
        _navigateToForm(file, DocumentSourceType.pdf);
      }
    } catch (e) {
      _showError('حدث خطأ أثناء اختيار الملف');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToForm(File file, DocumentSourceType sourceType, {File? additionalFile}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentFormScreen(
          file: file,
          sourceType: sourceType,
          additionalFile: additionalFile,
        ),
      ),
    );
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
        title: const Text('إضافة مستند'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر طريقة الإضافة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'يمكنك التقاط صورة جديدة أو اختيار ملف موجود',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Scan Option
                _AddOptionCard(
                  icon: Icons.camera_alt_outlined,
                  title: 'مسح ضوئي',
                  subtitle: 'التقط صورة للمستند بالكاميرا',
                  color: AppColors.primary,
                  onTap: _isLoading ? null : _openCamera,
                ),
                const SizedBox(height: 16),

                // Upload PDF Option
                _AddOptionCard(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'رفع ملف PDF',
                  subtitle: 'اختر ملف PDF من جهازك',
                  color: AppColors.error,
                  onTap: _isLoading ? null : _openFilePicker,
                ),
                const SizedBox(height: 16),

                // Gallery Option
                _AddOptionCard(
                  icon: Icons.photo_library_outlined,
                  title: 'من المعرض',
                  subtitle: 'اختر صورة من معرض الصور',
                  color: AppColors.secondary,
                  onTap: _isLoading ? null : _openGallery,
                ),

                const Spacer(),

                // Tip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outlined,
                        color: AppColors.info,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'نصيحة: للحصول على أفضل نتيجة، تأكد من إضاءة جيدة ووضع المستند على سطح مستوٍ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _AddOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.surfaceVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Document source type
enum DocumentSourceType {
  camera,
  gallery,
  pdf,
}
