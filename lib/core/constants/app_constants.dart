import 'secrets.dart';

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'صَوْن';
  static const String appNameEn = 'Sawn';
  static const String appTagline = 'كل مستنداتك في جيبك';
  static const String appVersion = '1.0.0';

  // Supabase (from secrets)
  static const String supabaseUrl = Secrets.supabaseUrl;
  static const String supabaseAnonKey = Secrets.supabaseAnonKey;

  // Google OAuth (from secrets)
  static const String googleClientIdAndroid = Secrets.googleClientIdAndroid;
  static const String googleClientIdIos = Secrets.googleClientIdIos;

  // Google Drive
  static const String driveFolderName = 'صَوْن';
  static const String driveFolderNameEn = 'Sawn';

  // Reminder Defaults
  static const int defaultReminderDays = 30;
  static const List<int> reminderOptions = [7, 30, 60, 90];

  // Validation
  static const int pinLength = 4;
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB (unlimited but reasonable)

  // Supported File Types
  static const List<String> supportedFileTypes = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'heic',
  ];

  // Default Categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'nameAr': 'شخصي', 'nameEn': 'Personal', 'icon': 'person_outlined'},
    {'nameAr': 'السيارة', 'nameEn': 'Car', 'icon': 'directions_car_outlined'},
    {'nameAr': 'العمل', 'nameEn': 'Work', 'icon': 'work_outlined'},
    {'nameAr': 'السكن', 'nameEn': 'Home', 'icon': 'home_outlined'},
  ];
}
