import '../../data/models/log_model.dart';

/// واجهة مستودع سجلات النشاط - Logs Repository Interface
abstract class ILogsRepository {
  /// إنشاء سجل - Create log entry
  Future<void> createLog(LogModel log);

  /// جلب جميع السجلات - Get all logs
  Future<List<LogModel>> getAllLogs({int limit = 100});

  /// تسجيل نشاط - Log activity helper
  Future<void> logActivity({
    required String userId,
    required String userName,
    required String action,
    required String actionLabel,
    String targetType = '',
    String targetId = '',
    String details = '',
  });
}
