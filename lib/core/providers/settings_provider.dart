import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key for storing theme mode preference
const String _themeModeKey = 'theme_mode';
const String _appLockEnabledKey = 'app_lock_enabled';
const String _notificationsEnabledKey = 'notifications_enabled';

/// Provider for theme mode state
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Notifier for managing theme mode state
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeModeKey);

    if (savedMode != null) {
      state = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> toggleDarkMode() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

/// Provider for app lock enabled state
final appLockEnabledProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) {
  return AppLockNotifier();
});

/// Notifier for managing app lock state
class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier() : super(false) {
    _loadAppLockSetting();
  }

  Future<void> _loadAppLockSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_appLockEnabledKey) ?? false;
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, enabled);
  }

  Future<void> toggle() async {
    await setAppLockEnabled(!state);
  }
}

/// Provider for notifications enabled state
final notificationsEnabledProvider = StateNotifierProvider<NotificationsNotifier, bool>((ref) {
  return NotificationsNotifier();
});

/// Notifier for managing notifications state
class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true) {
    _loadNotificationsSetting();
  }

  Future<void> _loadNotificationsSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<void> toggle() async {
    await setNotificationsEnabled(!state);
  }
}
