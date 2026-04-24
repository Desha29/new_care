import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../../../core/services/firebase/firebase_service.dart';
import '../models/log_model.dart';
import '../../domain/repositories/logs_repository.dart';

class LogsRepositoryImpl implements ILogsRepository {
  final _local = SqliteService.instance;
  final _sync = SyncManager.instance;
  final _remote = FirebaseService.instance;

  @override
  Future<void> createLog(LogModel log) async {
    await _local.insert('logs', log.toSqliteMap());
    await _sync.enqueue(
      tableName: 'logs',
      operation: 'create',
      docId: log.id,
      data: log.toMap(),
    );
  }

  @override
  Future<List<LogModel>> getAllLogs({int limit = 100}) async {
    final results = await _local.database.then((db) => db.query('logs', orderBy: 'timestamp DESC', limit: limit));
    if (results.isNotEmpty) {
      return results.map((m) => LogModel.fromMap(m, m['id'] as String)).toList();
    }
    return await _remote.getAllLogs();
  }

  @override
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: userName,
      action: action,
      actionLabel: actionLabel,
      targetType: targetType,
      targetId: targetId,
      details: details,
      timestamp: DateTime.now(),
    );
    await createLog(log);
  }
}
