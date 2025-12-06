import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// ثيم تطبيق صَوْن - التصميم النظيف (Clean Design)
/// مستوحى من Material Design 3 وتطبيقات Google
class AppTheme {
  AppTheme._();

  // ============================================
  // الثيم الفاتح (Light Theme)
  // ============================================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Rubik',

    // الألوان الأساسية
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primary,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
      onSurface: AppColors.textPrimary,
      onBackground: AppColors.textPrimary,
    ),

    // AppBar - نظيف وبسيط
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
      iconTheme: IconThemeData(
        color: AppColors.iconPrimary,
        size: 24,
      ),
    ),

    // البطاقات - بدون ظل أو ظل خفيف جداً
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    // حقول الإدخال - نظيفة
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    // الأزرار المرتفعة - بسيطة
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.surfaceVariant,
        disabledForegroundColor: AppColors.textDisabled,
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Rubik',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
        ),
      ),
    ),

    // الأزرار المحددة - شفافة مع حدود
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textDisabled,
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Rubik',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
        ),
      ),
    ),

    // أزرار النص - بدون خلفية
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textDisabled,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Rubik',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
        ),
      ),
    ),

    // شريط التنقل السفلي - نظيف
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.iconSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Navigation Bar (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.primary.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return const IconThemeData(color: AppColors.iconSecondary, size: 24);
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          );
        }
        return const TextStyle(
          fontFamily: 'Rubik',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        );
      }),
    ),

    // زر الإجراء العائم
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 2,
      focusElevation: 4,
      hoverElevation: 4,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 24,
      horizontalTitleGap: 16,
      iconColor: AppColors.iconPrimary,
      textColor: AppColors.textPrimary,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      disabledColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primary.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      labelStyle: const TextStyle(
        fontFamily: 'Rubik',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Rubik',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Rubik',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: const TextStyle(
        fontFamily: 'Rubik',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.background,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // النصوص
    textTheme: const TextTheme(
      // Headlines
      headlineLarge: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: -0.25,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.3,
      ),

      // Titles
      titleLarge: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // Body
      bodyLarge: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        letterSpacing: 0.25,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.25,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        letterSpacing: 0.25,
        height: 1.5,
      ),

      // Labels
      labelLarge: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.25,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.25,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        letterSpacing: 0.25,
        height: 1.4,
      ),
    ),
  );

  // ============================================
  // الثيم الليلي (Dark Theme)
  // ============================================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Rubik',

    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.backgroundDark,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.backgroundDark,
      secondary: AppColors.primaryLight,
      surface: AppColors.surfaceDark,
      background: AppColors.backgroundDark,
      error: AppColors.error,
      onSurface: AppColors.textPrimaryDark,
      onBackground: AppColors.textPrimaryDark,
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textPrimaryDark,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimaryDark,
      ),
      iconTheme: IconThemeData(
        color: AppColors.textSecondaryDark,
        size: 24,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: AppColors.borderDark,
          width: 1,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariantDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textTertiaryDark),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.backgroundDark,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.dividerDark,
      thickness: 1,
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimaryDark,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimaryDark,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimaryDark,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryDark,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondaryDark,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiaryDark,
      ),
    ),
  );
}
