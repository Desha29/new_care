import 'package:new_care/features/activity_logs/data/models/log_model.dart';

abstract class ILogsRepository {
  Future<void> createLog(LogModel log);
  Future<List<LogModel>> getAllLogs({int limit = 100});
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
