import 'package:flutter/material.dart';

/// ألوان التطبيق الرئيسية - App main colors
/// مستوحاة من شعار نيو كير (أزرق داكن + تركواز)
class AppColors {
  AppColors._();

  // === الألوان الأساسية - Primary Colors ===
  static const Color primary = Color(0xFF0D3B66); // أزرق داكن - Dark Navy
  static const Color primaryLight = Color(0xFF1A5276);
  static const Color primaryDark = Color(0xFF092A4A);

  // === الألوان الثانوية - Secondary Colors ===
  static const Color secondary = Color(0xFF5AB9C1); // تركواز - Teal/Turquoise
  static const Color secondaryLight = Color(0xFF7DD1D8);
  static const Color secondaryDark = Color(0xFF3E9EA6);

  // === ألوان الخلفية - Background Colors ===
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF7F9FC);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // === ألوان الشريط الجانبي - Sidebar Colors ===
  static const Color sidebarBackground = Color(0xFF0D3B66);
  static const Color sidebarItemActive = Color(0xFF5AB9C1);
  static const Color sidebarItemHover = Color(0xFF1A5276);
  static const Color sidebarText = Color(0xFFCBD5E1);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);

  // === ألوان النص - Text Colors ===
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // === ألوان الحالة - Status Colors ===
  static const Color statusPending = Color(0xFFF59E0B); // معلق - Pending (Yellow/Amber)
  static const Color statusPendingBg = Color(0xFFFEF3C7);
  static const Color statusInProgress = Color(0xFF3B82F6); // جاري التنفيذ - In Progress (Blue)
  static const Color statusInProgressBg = Color(0xFFDBEAFE);
  static const Color statusCompleted = Color(0xFF10B981); // منتهية - Completed (Green)
  static const Color statusCompletedBg = Color(0xFFD1FAE5);
  static const Color statusCancelled = Color(0xFFEF4444); // ملغية - Cancelled (Red)
  static const Color statusCancelledBg = Color(0xFFFEE2E2);

  // === ألوان الإجراءات - Action Colors ===
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // === ألوان الحدود - Border Colors ===
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // === ألوان الظل - Shadow Colors ===
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // === تدرج لوني - Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF1A5276)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, Color(0xFF3E9EA6)],
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D3B66), Color(0xFF092A4A)],
  );
}
