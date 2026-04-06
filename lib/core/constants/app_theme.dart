import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ثيم التطبيق - App Theme
/// تصميم احترافي لسطح المكتب مع دعم RTL والخط العربي Cairo
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      brightness: Brightness.light,

      // === Color Scheme ===
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textOnPrimary,
      ),

      // === Scaffold ===
      scaffoldBackgroundColor: AppColors.background,

      // === AppBar ===
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),

      // === Card ===
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // === Elevated Button ===
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // === Outlined Button ===
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // === Text Button ===
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // === Input Decoration ===
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),

      // === Data Table ===
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        dataTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
        ),
        headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
      ),

      // === Dialog ===
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),

      // === Divider ===
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // === Tooltip ===
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.textOnPrimary,
          fontSize: 12,
        ),
      ),

      // === Snackbar ===
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.textOnPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // === Checkbox ===
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.border;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // === Switch ===
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight.withValues(alpha: 0.4);
          }
          return AppColors.border;
        }),
      ),

      // === Tab Bar ===
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        indicatorColor: AppColors.primary,
      ),

      // === Text Theme ===
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 32, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 28, color: AppColors.textPrimary),
        displaySmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 24, color: AppColors.textPrimary),
        headlineLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 20, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
        titleSmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w400, fontSize: 16, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w400, fontSize: 14, color: AppColors.textPrimary),
        bodySmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w400, fontSize: 12, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
        labelMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.textSecondary),
        labelSmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w400, fontSize: 11, color: AppColors.textHint),
      ),
    );
  }
}
