import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مستنداتي'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Search
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              // TODO: Filter
            },
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'شاشة المستندات - سيتم تطويرها',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
