import 'package:flutter/material.dart';

/// مساعد الاستجابة - Responsive Helper
/// يوفر أدوات لتحديد حجم الشاشة والتخطيط المناسب
class ResponsiveHelper {
  ResponsiveHelper._();

  // === Breakpoints ===
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double wideDesktopBreakpoint = 1600;

  /// تحديد نوع الجهاز بناءً على عرض الشاشة
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    if (width < desktopBreakpoint) return DeviceType.desktop;
    return DeviceType.wideDesktop;
  }

  /// هل الشاشة موبايل؟
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// هل الشاشة تابلت؟
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// هل الشاشة سطح مكتب؟
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// هل الشاشة سطح مكتب عريض؟
  static bool isWideDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= wideDesktopBreakpoint;

  /// عدد أعمدة الشبكة حسب حجم الشاشة
  static int getGridColumns(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
      case DeviceType.wideDesktop:
        return 4;
    }
  }

  /// عدد أعمدة بطاقات الإحصائيات
  static int getStatCardColumns(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
      case DeviceType.wideDesktop:
        return 4;
    }
  }

  /// حجم الحشو الخارجي حسب الشاشة
  static double getScreenPadding(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 12;
      case DeviceType.tablet:
        return 16;
      case DeviceType.desktop:
        return 24;
      case DeviceType.wideDesktop:
        return 24;
    }
  }

  /// حجم الخط الرئيسي حسب الشاشة
  static double getTitleFontSize(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 18;
      case DeviceType.tablet:
        return 20;
      case DeviceType.desktop:
      case DeviceType.wideDesktop:
        return 26;
    }
  }

  /// حجم الخط الثانوي
  static double getSubtitleFontSize(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 11;
      case DeviceType.tablet:
        return 12;
      case DeviceType.desktop:
      case DeviceType.wideDesktop:
        return 13;
    }
  }

  /// النسبة المئوية لعرض العنصر
  static double getAspectRatio(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 2.5;
      case DeviceType.tablet:
        return 2.0;
      case DeviceType.desktop:
      case DeviceType.wideDesktop:
        return 1.8;
    }
  }

  /// هل يجب إظهار الشريط الجانبي كـ Drawer؟
  static bool shouldShowDrawer(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  /// عرض الشريط الجانبي حسب الشاشة
  static double getSidebarWidth(BuildContext context) {
    if (isMobile(context)) return 260;
    if (isTablet(context)) return 220;
    return 260;
  }

  /// اختيار قيمة حسب نوع الجهاز
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? desktop;
      case DeviceType.desktop:
      case DeviceType.wideDesktop:
        return desktop;
    }
  }
}

/// أنواع الأجهزة
enum DeviceType {
  mobile,
  tablet,
  desktop,
  wideDesktop,
}

/// ويدجت بناء متجاوب - Responsive Layout Builder
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < ResponsiveHelper.mobileBreakpoint) {
          return mobile;
        }
        if (constraints.maxWidth < ResponsiveHelper.tabletBreakpoint) {
          return tablet ?? desktop;
        }
        return desktop;
      },
    );
  }
}
