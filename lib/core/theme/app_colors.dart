import 'package:flutter/material.dart';

/// ألوان تطبيق صَوْن - التصميم النظيف (Clean Design)
/// مستوحى من تطبيقات Google الحديثة
class AppColors {
  AppColors._();

  // ============================================
  // اللون الأساسي (يُستخدم باعتدال)
  // ============================================
  static const Color primary = Color(0xFF1A73E8);        // أزرق Google
  static const Color primaryLight = Color(0xFF4285F4);
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ============================================
  // الخلفيات
  // ============================================
  static const Color background = Color(0xFFFFFFFF);      // أبيض نقي
  static const Color surface = Color(0xFFFAFAFA);         // رمادي فاتح جداً
  static const Color surfaceVariant = Color(0xFFF1F3F4);  // للبطاقات
  static const Color surfaceElevated = Color(0xFFFFFFFF); // للعناصر المرتفعة

  // ============================================
  // النصوص
  // ============================================
  static const Color textPrimary = Color(0xFF202124);     // أسود Google
  static const Color textSecondary = Color(0xFF5F6368);   // رمادي متوسط
  static const Color textTertiary = Color(0xFF9AA0A6);    // رمادي فاتح
  static const Color textDisabled = Color(0xFFBDC1C6);    // معطل

  // ============================================
  // الحدود والفواصل
  // ============================================
  static const Color border = Color(0xFFDADCE0);          // حدود خفيفة
  static const Color borderLight = Color(0xFFE8EAED);     // حدود أخف
  static const Color divider = Color(0xFFE8EAED);         // فواصل

  // ============================================
  // حالات النظام (تظهر عند الحاجة فقط)
  // ============================================
  static const Color error = Color(0xFFD93025);           // أحمر Google
  static const Color errorLight = Color(0xFFFCE8E6);      // خلفية الخطأ
  static const Color success = Color(0xFF1E8E3E);         // أخضر Google
  static const Color successLight = Color(0xFFE6F4EA);    // خلفية النجاح
  static const Color warning = Color(0xFFF9AB00);         // أصفر Google
  static const Color warningLight = Color(0xFFFEF7E0);    // خلفية التحذير
  static const Color info = Color(0xFF1A73E8);            // أزرق
  static const Color infoLight = Color(0xFFE8F0FE);       // خلفية المعلومات

  // ============================================
  // الأيقونات
  // ============================================
  static const Color iconPrimary = Color(0xFF5F6368);     // أيقونات عادية
  static const Color iconSecondary = Color(0xFF9AA0A6);   // أيقونات ثانوية
  static const Color iconActive = Color(0xFF1A73E8);      // أيقونات نشطة

  // ============================================
  // التفاعلات
  // ============================================
  static const Color ripple = Color(0x1F000000);          // تأثير الضغط
  static const Color hover = Color(0x0A000000);           // تأثير التمرير
  static const Color focus = Color(0x1F1A73E8);           // تأثير التركيز

  // ============================================
  // الوضع الليلي (Dark Mode)
  // ============================================
  static const Color backgroundDark = Color(0xFF202124);
  static const Color surfaceDark = Color(0xFF292A2D);
  static const Color surfaceVariantDark = Color(0xFF35363A);
  static const Color textPrimaryDark = Color(0xFFE8EAED);
  static const Color textSecondaryDark = Color(0xFF9AA0A6);
  static const Color textTertiaryDark = Color(0xFF5F6368);
  static const Color borderDark = Color(0xFF3C4043);
  static const Color dividerDark = Color(0xFF3C4043);

  // ============================================
  // ألوان التصنيفات (خفيفة - تظهر كخلفية فقط عند التحديد)
  // ============================================
  static const Color categoryPersonalBg = Color(0xFFF3E8FD);   // بنفسجي فاتح
  static const Color categoryCarBg = Color(0xFFFEF3E0);        // برتقالي فاتح
  static const Color categoryWorkBg = Color(0xFFE0F7FA);       // سماوي فاتح
  static const Color categoryHomeBg = Color(0xFFFCE4EC);       // وردي فاتح

  // Aliases for category colors (for backward compatibility)
  static const Color categoryPersonal = Color(0xFF8B5CF6);     // بنفسجي
  static const Color categoryCar = Color(0xFFF59E0B);          // برتقالي
  static const Color categoryWork = Color(0xFF06B6D4);         // سماوي
  static const Color categoryHome = Color(0xFFEC4899);         // وردي

  // Secondary color for UI elements
  static const Color secondary = Color(0xFF8B5CF6);            // بنفسجي للعناصر الثانوية

  // ============================================
  // Gradient للشعار فقط
  // ============================================
  static const LinearGradient logoGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
