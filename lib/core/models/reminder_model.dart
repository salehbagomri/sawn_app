/// Reminder model matching Supabase schema
class ReminderModel {
  final String id;
  final String documentId;
  final String userId;
  final DateTime remindDate;
  final int daysBefore;
  final bool isSent;
  final bool isRead;
  final DateTime createdAt;

  // Joined data
  final String? documentTitle;
  final String? documentCategory;

  ReminderModel({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.remindDate,
    required this.daysBefore,
    this.isSent = false,
    this.isRead = false,
    DateTime? createdAt,
    this.documentTitle,
    this.documentCategory,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if reminder is due (today or past)
  bool get isDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final remindDay = DateTime(remindDate.year, remindDate.month, remindDate.day);
    return remindDay.isBefore(today) || remindDay.isAtSameMomentAs(today);
  }

  /// Check if reminder is upcoming (within 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final daysUntil = remindDate.difference(now).inDays;
    return daysUntil > 0 && daysUntil <= 7;
  }

  /// Get human readable days before text
  String get daysBeforeText {
    switch (daysBefore) {
      case 7:
        return 'قبل أسبوع';
      case 30:
        return 'قبل شهر';
      case 60:
        return 'قبل شهرين';
      case 90:
        return 'قبل 3 أشهر';
      default:
        return 'قبل $daysBefore يوم';
    }
  }

  /// Create from Supabase JSON
  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      userId: json['user_id'] as String,
      remindDate: DateTime.parse(json['remind_date'] as String),
      daysBefore: json['days_before'] as int,
      isSent: json['is_sent'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      documentTitle: json['documents']?['title'] as String?,
      // We store category in document_type column
      documentCategory: json['documents']?['document_type'] as String?,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'user_id': userId,
      'remind_date': remindDate.toIso8601String().split('T').first,
      'days_before': daysBefore,
      'is_sent': isSent,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ReminderModel copyWith({
    String? id,
    String? documentId,
    String? userId,
    DateTime? remindDate,
    int? daysBefore,
    bool? isSent,
    bool? isRead,
    DateTime? createdAt,
    String? documentTitle,
    String? documentCategory,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      remindDate: remindDate ?? this.remindDate,
      daysBefore: daysBefore ?? this.daysBefore,
      isSent: isSent ?? this.isSent,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      documentTitle: documentTitle ?? this.documentTitle,
      documentCategory: documentCategory ?? this.documentCategory,
    );
  }
}

/// Predefined reminder options
class ReminderOption {
  final int daysBefore;
  final String labelAr;
  final bool isSelected;

  const ReminderOption({
    required this.daysBefore,
    required this.labelAr,
    this.isSelected = false,
  });

  static List<ReminderOption> get defaultOptions => [
        const ReminderOption(daysBefore: 7, labelAr: 'قبل أسبوع'),
        const ReminderOption(daysBefore: 30, labelAr: 'قبل شهر'),
        const ReminderOption(daysBefore: 60, labelAr: 'قبل شهرين'),
        const ReminderOption(daysBefore: 90, labelAr: 'قبل 3 أشهر'),
      ];

  ReminderOption copyWith({bool? isSelected}) {
    return ReminderOption(
      daysBefore: daysBefore,
      labelAr: labelAr,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
