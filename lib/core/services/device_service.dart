import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// خدمة الجهاز - Device Service
/// تحديد هوية الجهاز والتحقق منه
class DeviceService {
  static DeviceService? _instance;
  static const String _deviceIdKey = 'new_care_device_id';

  DeviceService._();

  static DeviceService get instance {
    _instance ??= DeviceService._();
    return _instance!;
  }

  String? _cachedDeviceId;

  /// الحصول على معرف الجهاز - Get Device ID
  /// يستخدم معرف فريد مخزن محليًا (يُنشأ مرة واحدة عند أول تشغيل)
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null || deviceId.isEmpty) {
      // Generate a new unique device ID
      deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    _cachedDeviceId = deviceId;
    return deviceId;
  }

  /// توليد معرف جهاز فريد - Generate unique device ID
  String _generateDeviceId() {
    final uuid = const Uuid().v4();
    final platform = _getPlatformName();
    final hostname = Platform.localHostname;
    return '${platform}_${hostname}_$uuid';
  }

  /// اسم المنصة - Platform name
  String _getPlatformName() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// التحقق من معرف الجهاز - Verify device ID
  /// يقارن المعرف الحالي مع قائمة المعرفات المسموح بها
  Future<bool> verifyDevice(List<String> allowedDeviceIds) async {
    if (allowedDeviceIds.isEmpty) return true; // No restriction
    final currentDeviceId = await getDeviceId();
    return allowedDeviceIds.contains(currentDeviceId);
  }

  /// معلومات الجهاز - Device info
  Map<String, String> getDeviceInfo() {
    return {
      'platform': _getPlatformName(),
      'hostname': Platform.localHostname,
      'os': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
    };
  }
}
