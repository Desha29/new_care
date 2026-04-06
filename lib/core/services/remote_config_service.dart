import 'package:firebase_remote_config/firebase_remote_config.dart';

/// خدمة التحكم عن بُعد - Remote Config Service
/// Feature flags, force update, kill switch
class RemoteConfigService {
  static RemoteConfigService? _instance;
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService._() : _remoteConfig = FirebaseRemoteConfig.instance;

  static RemoteConfigService get instance {
    _instance ??= RemoteConfigService._();
    return _instance!;
  }

  /// تهيئة Remote Config - Initialize
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // القيم الافتراضية - Default values
    await _remoteConfig.setDefaults({
      'force_update': false,
      'kill_switch': false,
      'min_version': '1.0.0',
      'maintenance_mode': false,
      'enable_printing': true,
      'enable_backup': true,
      'enable_reports': true,
      'maintenance_message': 'النظام تحت الصيانة حالياً',
    });

    // جلب القيم - Fetch values
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // استخدام القيم الافتراضية في حالة عدم الاتصال
    }
  }

  /// هل يجب التحديث الإجباري؟ - Force update required?
  bool get isForceUpdateRequired => _remoteConfig.getBool('force_update');

  /// هل النظام متوقف؟ - Kill switch active?
  bool get isKillSwitchActive => _remoteConfig.getBool('kill_switch');

  /// الحد الأدنى للإصدار - Minimum version
  String get minVersion => _remoteConfig.getString('min_version');

  /// هل وضع الصيانة مفعل؟ - Maintenance mode?
  bool get isMaintenanceMode => _remoteConfig.getBool('maintenance_mode');

  /// هل الطباعة مفعلة؟ - Printing enabled?
  bool get isPrintingEnabled => _remoteConfig.getBool('enable_printing');

  /// هل النسخ الاحتياطي مفعل؟ - Backup enabled?
  bool get isBackupEnabled => _remoteConfig.getBool('enable_backup');

  /// هل التقارير مفعلة؟ - Reports enabled?
  bool get isReportsEnabled => _remoteConfig.getBool('enable_reports');

  /// رسالة الصيانة - Maintenance message
  String get maintenanceMessage => _remoteConfig.getString('maintenance_message');

  /// تحديث القيم - Refresh values
  Future<bool> refresh() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (e) {
      return false;
    }
  }

  /// جلب جميع الأعلام - Get all feature flags
  Map<String, dynamic> getAllFlags() {
    return {
      'force_update': isForceUpdateRequired,
      'kill_switch': isKillSwitchActive,
      'min_version': minVersion,
      'maintenance_mode': isMaintenanceMode,
      'enable_printing': isPrintingEnabled,
      'enable_backup': isBackupEnabled,
      'enable_reports': isReportsEnabled,
      'maintenance_message': maintenanceMessage,
    };
  }
}
