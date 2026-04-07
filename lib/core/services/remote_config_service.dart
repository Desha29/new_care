import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// خدمة التحكم عن بُعد - Remote Config Service
/// Feature flags, force update, kill switch
class RemoteConfigService {
  static RemoteConfigService? _instance;
  final FirebaseRemoteConfig _remoteConfig;
  bool _isSupported = true;

  final Map<String, dynamic> _defaults = {
    'force_update': false,
    'kill_switch': false,
    'min_version': '1.0.0',
    'maintenance_mode': false,
    'enable_printing': true,
    'enable_backup': true,
    'enable_reports': true,
    'maintenance_message': 'النظام تحت الصيانة حالياً',
  };

  RemoteConfigService._() : _remoteConfig = FirebaseRemoteConfig.instance;

  static RemoteConfigService get instance {
    _instance ??= RemoteConfigService._();
    return _instance!;
  }

  /// تهيئة Remote Config - Initialize
  Future<void> initialize() async {
    // Windows and other desktop platforms often throw 'Null is not a subtype of int' 
    // when setting config settings via MethodChannel.
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux)) {
       _isSupported = false;
       debugPrint('RemoteConfig disabled for desktop platform.');
       return;
    }

    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // القيم الافتراضية - Default values
      await _remoteConfig.setDefaults(_defaults);

      // جلب القيم - Fetch values
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('RemoteConfig init error (likely unsupported platform): $e');
      _isSupported = false;
    }
  }

  /// هل يجب التحديث الإجباري؟ - Force update required?
  bool get isForceUpdateRequired => _isSupported ? _remoteConfig.getBool('force_update') : _defaults['force_update'];

  /// هل النظام متوقف؟ - Kill switch active?
  bool get isKillSwitchActive => _isSupported ? _remoteConfig.getBool('kill_switch') : _defaults['kill_switch'];

  /// الحد الأدنى للإصدار - Minimum version
  String get minVersion => _isSupported ? _remoteConfig.getString('min_version') : _defaults['min_version'];

  /// هل وضع الصيانة مفعل؟ - Maintenance mode?
  bool get isMaintenanceMode => _isSupported ? _remoteConfig.getBool('maintenance_mode') : _defaults['maintenance_mode'];

  /// هل الطباعة مفعلة؟ - Printing enabled?
  bool get isPrintingEnabled => _isSupported ? _remoteConfig.getBool('enable_printing') : _defaults['enable_printing'];

  /// هل النسخ الاحتياطي مفعل؟ - Backup enabled?
  bool get isBackupEnabled => _isSupported ? _remoteConfig.getBool('enable_backup') : _defaults['enable_backup'];

  /// هل التقارير مفعلة؟ - Reports enabled?
  bool get isReportsEnabled => _isSupported ? _remoteConfig.getBool('enable_reports') : _defaults['enable_reports'];

  /// رسالة الصيانة - Maintenance message
  String get maintenanceMessage => _isSupported ? _remoteConfig.getString('maintenance_message') : _defaults['maintenance_message'];

  /// تحديث القيم - Refresh values
  Future<bool> refresh() async {
    if (!_isSupported) return false;
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
