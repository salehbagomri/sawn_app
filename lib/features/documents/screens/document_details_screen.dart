import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DocumentDetailsScreen extends StatelessWidget {
  final String documentId;

  const DocumentDetailsScreen({
    super.key,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل المستند'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Edit
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () {
              // TODO: More options
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'تفاصيل المستند: $documentId\nسيتم تطويرها',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
