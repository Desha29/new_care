/// ثوابت التطبيق - App Constants
class AppConstants {
  AppConstants._();

  // === Firestore Collections ===
  static const String usersCollection = 'users';
  static const String patientsCollection = 'patients';
  static const String casesCollection = 'cases';
  static const String inventoryCollection = 'inventory';
  static const String logsCollection = 'logs';
  static const String settingsCollection = 'settings';
  static const String expensesCollection = 'expenses';

  // === SQLite Database ===
  static const String dbName = 'new_care_backup.db';
  static const int dbVersion = 1;

  // === Remote Config Keys ===
  static const String rcForceUpdate = 'force_update';
  static const String rcKillSwitch = 'kill_switch';
  static const String rcMinVersion = 'min_version';
  static const String rcMaintenanceMode = 'maintenance_mode';
  static const String rcEnablePrinting = 'enable_printing';
  static const String rcEnableBackup = 'enable_backup';
  static const String rcEnableReports = 'enable_reports';

  // === Pagination ===
  static const int pageSize = 20;

  // === Date Formats ===
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';

  // === App Info ===
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // === Sidebar Width ===
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 70.0;

  // === Animation Durations ===
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}
