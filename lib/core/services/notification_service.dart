import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/document_model.dart';
import '../models/reminder_model.dart';

/// Service for handling local notifications
class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Notification channel details for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sawn_reminders',
    'تذكيرات المستندات',
    description: 'إشعارات تذكير بانتهاء صلاحية المستندات',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('NotificationService: Initializing...');

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _isInitialized = true;
    debugPrint('NotificationService: Initialized successfully');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('NotificationService: Notification tapped: ${response.payload}');
    // TODO: Navigate to document details
  }

  /// Request notification permissions (for Android 13+)
  Future<bool> requestPermissions() async {
    debugPrint('NotificationService: Requesting permissions...');

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      debugPrint('NotificationService: Permission granted: $granted');
      return granted ?? false;
    }

    return true;
  }

  /// Check if exact alarms are permitted (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      return await android.canScheduleExactNotifications() ?? false;
    }
    return true;
  }

  /// Schedule a reminder notification
  Future<bool> scheduleReminder({
    required ReminderModel reminder,
    required String documentTitle,
    required DocumentCategory category,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final scheduledDate = tz.TZDateTime.from(reminder.remindDate, tz.local);

      // Don't schedule if date is in the past
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('NotificationService: Skipping past reminder');
        return false;
      }

      final notificationId = reminder.id.hashCode;

      // Notification details
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          'المستند "$documentTitle" سينتهي خلال ${reminder.daysBefore} ${reminder.daysBefore == 1 ? "يوم" : "أيام"}',
          contentTitle: 'تذكير: ${category.nameAr}',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        'تذكير: ${category.nameAr}',
        'المستند "$documentTitle" سينتهي خلال ${reminder.daysBefore} ${reminder.daysBefore == 1 ? "يوم" : "أيام"}',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.documentId,
      );

      debugPrint(
          'NotificationService: Scheduled reminder for ${scheduledDate.toString()}');
      return true;
    } catch (e, stackTrace) {
      debugPrint('NotificationService: Error scheduling reminder: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Cancel a specific reminder notification
  Future<void> cancelReminder(String reminderId) async {
    final notificationId = reminderId.hashCode;
    await _notifications.cancel(notificationId);
    debugPrint('NotificationService: Cancelled reminder $reminderId');
  }

  /// Cancel all notifications for a document
  Future<void> cancelDocumentReminders(String documentId) async {
    // We'll need to track notification IDs per document
    // For now, we can't cancel by document ID directly
    debugPrint(
        'NotificationService: Would cancel all reminders for document $documentId');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('NotificationService: Cancelled all notifications');
  }

  /// Show an immediate notification (for testing)
  Future<void> showTestNotification() async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'sawn_reminders',
      'تذكيرات المستندات',
      channelDescription: 'إشعارات تذكير بانتهاء صلاحية المستندات',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'اختبار الإشعارات',
      'تم إعداد الإشعارات بنجاح!',
      details,
    );

    debugPrint('NotificationService: Showed test notification');
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
