import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/activity_logs/data/models/log_model.dart';
import '../../constants/app_constants.dart';
import 'firebase_base.dart';

/// مستودع السجلات - Logs Repository
class LogsRepository extends FirebaseBase {
  CollectionReference get _logsRef =>
      firestore.collection(AppConstants.logsCollection);

  /// إنشاء سجل - Create log entry
  Future<void> createLog(LogModel log) async {
    await _logsRef.doc(log.id).set(log.toMap());
  }

  /// جلب جميع السجلات - Get all logs
  Future<List<LogModel>> getAllLogs({int limit = 100}) async {
    final snapshot = await _logsRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => LogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// تسجيل نشاط - Log activity helper
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
      id: generateId(),
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
