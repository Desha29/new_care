import 'package:uuid/uuid.dart';
import '../../features/activity_logs/data/models/log_model.dart';
import 'sqlite_service.dart';

/// خدمة السجلات المحلية - Local Logs Service
/// تخزين جميع سجلات الأنشطة في SQLite محلياً
class LocalLogService {
  static LocalLogService? _instance;
  final SqliteService _sqlite = SqliteService.instance;
  final Uuid _uuid = const Uuid();

  LocalLogService._();

  static LocalLogService get instance {
    _instance ??= LocalLogService._();
    return _instance!;
  }

  /// تسجيل نشاط - Log activity
  Future<void> logActivity({
    required String userId,
    required String userName,
    required String action,
    required String actionLabel,
    String targetType = '',
    String targetId = '',
    String details = '',
  }) async {
    final log = LogModel(
      id: _uuid.v4(),
      userId: userId,
      userName: userName,
      action: action,
      actionLabel: actionLabel,
      targetType: targetType,
      targetId: targetId,
      details: details,
      timestamp: DateTime.now(),
    );
    await _sqlite.insert('logs', log.toSqliteMap());
  }

  /// جلب جميع السجلات - Get all logs
  Future<List<LogModel>> getAllLogs({int limit = 200}) async {
    final db = await _sqlite.database;
    final results = await db.query(
      'logs',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return results.map((m) => LogModel.fromSqliteMap(m)).toList();
  }

  /// بحث في السجلات - Search logs
  Future<List<LogModel>> searchLogs(String query) async {
    final db = await _sqlite.database;
    final results = await db.query(
      'logs',
      where: 'userName LIKE ? OR action LIKE ? OR actionLabel LIKE ? OR details LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );
    return results.map((m) => LogModel.fromSqliteMap(m)).toList();
  }

  /// حذف السجلات القديمة - Clear old logs (older than 30 days)
  Future<void> clearOldLogs({int daysToKeep = 30}) async {
    final db = await _sqlite.database;
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    await db.delete(
      'logs',
      where: 'timestamp < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }

  /// عدد السجلات - Logs count
  Future<int> getLogsCount() async {
    final db = await _sqlite.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM logs');
    return result.first['count'] as int;
  }
}
