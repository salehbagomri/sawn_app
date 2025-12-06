import 'package:flutter/material.dart';

/// Document categories
enum DocumentCategory {
  personal('شخصي', 'personal', Icons.person_outlined),
  car('السيارة', 'car', Icons.directions_car_outlined),
  work('العمل', 'work', Icons.work_outlined),
  home('السكن', 'home', Icons.home_outlined);

  final String nameAr;
  final String nameEn;
  final IconData icon;

  const DocumentCategory(this.nameAr, this.nameEn, this.icon);

  static DocumentCategory fromString(String value) {
    return DocumentCategory.values.firstWhere(
      (e) => e.nameEn == value || e.nameAr == value,
      orElse: () => DocumentCategory.personal,
    );
  }
}

/// Document status based on expiry date
enum DocumentStatus {
  valid('ساري'),
  expiringSoon('ينتهي قريباً'),
  expired('منتهي'),
  noExpiry('بدون تاريخ');

  final String nameAr;
  const DocumentStatus(this.nameAr);
}

/// Document model matching Supabase schema
class DocumentModel {
  final String id;
  final String userId;
  final String? categoryId;
  final DocumentCategory category;
  final String title;
  final String? documentType;
  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? notes;
  final bool isFavorite;
  final bool isOffline;
  final String? driveFileId;
  final String? driveFileUrl;
  final String? localPath;
  final Map<String, dynamic>? extractedData;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.category,
    required this.title,
    this.documentType,
    this.documentNumber,
    this.issueDate,
    this.expiryDate,
    this.notes,
    this.isFavorite = false,
    this.isOffline = false,
    this.driveFileId,
    this.driveFileUrl,
    this.localPath,
    this.extractedData,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Get document status based on expiry date
  DocumentStatus get status {
    if (expiryDate == null) return DocumentStatus.noExpiry;

    final now = DateTime.now();
    final daysUntilExpiry = expiryDate!.difference(now).inDays;

    if (daysUntilExpiry < 0) return DocumentStatus.expired;
    if (daysUntilExpiry <= 30) return DocumentStatus.expiringSoon;
    return DocumentStatus.valid;
  }

  /// Get days until expiry (negative if expired)
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// Check if document is expiring within given days
  bool isExpiringWithin(int days) {
    if (expiryDate == null) return false;
    final daysLeft = daysUntilExpiry ?? 0;
    return daysLeft >= 0 && daysLeft <= days;
  }

  /// Create from Supabase JSON
  /// Note: We read category from 'document_type' since that's where we store it
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      // Read category from document_type (where we store it)
      category: DocumentCategory.fromString(json['document_type'] ?? 'personal'),
      title: json['title'] as String,
      documentType: json['document_type'] as String?,
      documentNumber: json['document_number'] as String?,
      issueDate: json['issue_date'] != null
          ? DateTime.parse(json['issue_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      notes: json['notes'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      isOffline: json['is_offline'] as bool? ?? false,
      driveFileId: json['drive_file_id'] as String?,
      driveFileUrl: json['drive_file_url'] as String?,
      localPath: json['local_path'] as String?,
      extractedData: json['extracted_data'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase JSON
  /// Note: We store 'category' in 'document_type' field since the Supabase table
  /// doesn't have a dedicated category column (it uses category_id as FK).
  /// The 'local_path' is only stored locally, not in Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      // We use document_type to store category since we're not using category_id FK
      'document_type': category.nameEn,
      'title': title,
      'document_number': documentNumber,
      'issue_date': issueDate?.toIso8601String().split('T').first,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'notes': notes,
      'is_favorite': isFavorite,
      'is_offline': isOffline,
      'drive_file_id': driveFileId,
      'drive_file_url': driveFileUrl,
      'extracted_data': extractedData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  DocumentModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    DocumentCategory? category,
    String? title,
    String? documentType,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    bool? isFavorite,
    bool? isOffline,
    String? driveFileId,
    String? driveFileUrl,
    String? localPath,
    Map<String, dynamic>? extractedData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      title: title ?? this.title,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      isOffline: isOffline ?? this.isOffline,
      driveFileId: driveFileId ?? this.driveFileId,
      driveFileUrl: driveFileUrl ?? this.driveFileUrl,
      localPath: localPath ?? this.localPath,
      extractedData: extractedData ?? this.extractedData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
