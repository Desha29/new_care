/// مسافات التصميم - Design Spacing Tokens
/// نظام مسافات موحد مبني على شبكة 4px
/// Unified spacing system based on a 4px grid
class AppSpacing {
  AppSpacing._();

  // === المسافات الأساسية - Base Spacing (4px grid) ===
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // === مسافات الأقسام - Section Spacing ===
  static const double sectionGap = 24.0;
  static const double sectionGapLarge = 32.0;
  static const double pageMargin = 24.0;
  static const double pagePadding = 20.0;

  // === مسافات البطاقات - Card Spacing ===
  static const double cardPadding = 16.0;
  static const double cardPaddingLarge = 20.0;
  static const double cardMargin = 8.0;
  static const double cardGap = 12.0;

  // === مسافات الحقول - Form Field Spacing ===
  static const double fieldGap = 12.0;
  static const double fieldPaddingH = 16.0;
  static const double fieldPaddingV = 14.0;
  static const double labelGap = 6.0;

  // === مسافات الأزرار - Button Spacing ===
  static const double buttonPaddingH = 24.0;
  static const double buttonPaddingV = 14.0;
  static const double buttonGap = 12.0;
  static const double iconButtonSize = 40.0;

  // === مسافات الجداول - Table Spacing ===
  static const double tableCellPaddingH = 16.0;
  static const double tableCellPaddingV = 12.0;
  static const double tableHeaderHeight = 48.0;
  static const double tableRowHeight = 52.0;

  // === مسافات الشريط الجانبي - Sidebar Spacing ===
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 72.0;
  static const double sidebarItemPaddingH = 16.0;
  static const double sidebarItemPaddingV = 12.0;

  // === الحواف الدائرية - Border Radius ===
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusRound = 100.0;

  // === أحجام الأيقونات - Icon Sizes ===
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
}
