import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Category model matching Supabase schema
class CategoryModel {
  final String id;
  final String userId;
  final String nameAr;
  final String nameEn;
  final String icon;
  final Color color;
  final String? driveFolderId;
  final bool isDefault;
  final int documentCount;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.userId,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.color,
    this.driveFolderId,
    this.isDefault = false,
    this.documentCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get IconData from icon string
  IconData get iconData {
    switch (icon) {
      case 'person_outlined':
        return Icons.person_outlined;
      case 'directions_car_outlined':
        return Icons.directions_car_outlined;
      case 'work_outlined':
        return Icons.work_outlined;
      case 'home_outlined':
        return Icons.home_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  /// Default categories
  static List<CategoryModel> get defaultCategories => [
        CategoryModel(
          id: 'personal',
          userId: '',
          nameAr: 'شخصي',
          nameEn: 'personal',
          icon: 'person_outlined',
          color: AppColors.categoryPersonal,
          isDefault: true,
        ),
        CategoryModel(
          id: 'car',
          userId: '',
          nameAr: 'السيارة',
          nameEn: 'car',
          icon: 'directions_car_outlined',
          color: AppColors.categoryCar,
          isDefault: true,
        ),
        CategoryModel(
          id: 'work',
          userId: '',
          nameAr: 'العمل',
          nameEn: 'work',
          icon: 'work_outlined',
          color: AppColors.categoryWork,
          isDefault: true,
        ),
        CategoryModel(
          id: 'home',
          userId: '',
          nameAr: 'السكن',
          nameEn: 'home',
          icon: 'home_outlined',
          color: AppColors.categoryHome,
          isDefault: true,
        ),
      ];

  /// Create from Supabase JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      icon: json['icon'] as String? ?? 'folder_outlined',
      color: _colorFromString(json['color'] as String?),
      driveFolderId: json['drive_folder_id'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      documentCount: json['document_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'icon': icon,
      'drive_folder_id': driveFolderId,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Parse color from string
  static Color _colorFromString(String? colorStr) {
    if (colorStr == null) return AppColors.primary;
    switch (colorStr) {
      case 'categoryPersonal':
        return AppColors.categoryPersonal;
      case 'categoryCar':
        return AppColors.categoryCar;
      case 'categoryWork':
        return AppColors.categoryWork;
      case 'categoryHome':
        return AppColors.categoryHome;
      default:
        return AppColors.primary;
    }
  }

  /// Create a copy with updated fields
  CategoryModel copyWith({
    String? id,
    String? userId,
    String? nameAr,
    String? nameEn,
    String? icon,
    Color? color,
    String? driveFolderId,
    bool? isDefault,
    int? documentCount,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      driveFolderId: driveFolderId ?? this.driveFolderId,
      isDefault: isDefault ?? this.isDefault,
      documentCount: documentCount ?? this.documentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
