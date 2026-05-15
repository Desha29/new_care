import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';
import '../models/attendance_session_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// تنفيذ مستودع الحالات (الجيل الثاني) - Attendance Repository Implementation v2
/// Robust, offline-first attendance tracking.
class AttendanceRepositoryImpl implements IAttendanceRepository {
  final _local = SqliteService.instance;
  final _remote = FirebaseService.instance;
  final _sync = SyncManager.instance;

  @override
  Future<void> checkIn(AttendanceModel attendance) async {
    // 1. Save locally
    await _local.insert('attendance', attendance.toSqliteMap());
    // 2. Queue for sync
    await _sync.enqueue(
      tableName: 'attendance',
      operation: 'create',
      docId: attendance.id,
      data: attendance.toMap(),
    );
  }

  @override
  Future<void> checkOut(String attendanceId) async {
    // 1. Update locally
    final localRecord = await _local.getById('attendance', attendanceId);
    if (localRecord != null) {
      final updated = Map<String, dynamic>.from(localRecord);
      updated['checkOutTime'] = DateTime.now().toIso8601String();
      updated['status'] = 'checked_out';
      await _local.insert('attendance', updated);
    }

    // 2. Queue for sync
    await _sync.enqueue(
      tableName: 'attendance',
      operation: 'update',
      docId: attendanceId,
      data: {}, // checkOut logic in SyncManager handles timestamp
    );
  }

  @override
  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    // Check local first
    final db = await _local.database;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final results = await db.query(
      'attendance',
      where: 'userId = ? AND date = ?',
      whereArgs: [userId, todayStr],
      orderBy: 'checkInTime DESC',
      limit: 1,
    );

    if (results.isNotEmpty) {
      return AttendanceModel.fromMap(
        results.first,
        results.first['id'] as String,
      );
    }

    // Fallback to remote if online
    final remote = await _remote.getTodayAttendance(userId);
    if (remote != null) {
      await _local.insert('attendance', remote.toSqliteMap());
    }
    return remote;
  }

  @override
  Future<bool> isCheckedInToday(String userId) async {
    final attendance = await getTodayAttendance(userId);
    return attendance != null && attendance.isCheckedIn;
  }

  @override
  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(
    int year,
    int month,
  ) async {
    // For reports, we might want to fetch from remote to ensure full data
    return await _remote.getMonthlyAttendanceRecords(year, month);
  }

  @override
  Future<List<AttendanceModel>> getTodayAttendanceRecords() async {
    final db = await _local.database;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final results = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [todayStr],
    );
    return results
        .map((m) => AttendanceModel.fromMap(m, m['id'] as String))
        .toList();
  }



  @override
  Stream<List<AttendanceModel>> streamTodayAttendanceRecords() {
    final today = _getTodayString();
    final query = FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isEqualTo: today);

    return query.snapshots().map((snapshot) {
      final records = snapshot.docs
          .map(
            (doc) => AttendanceModel.fromMap(
              doc.data(),
              doc.id,
            ),
          )
          .toList();
      // Sort in code instead of Firestore
      records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return records;
    });
  }

  /// Helper method to get today's date as yyyy-MM-dd format
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<PaginatedResult<AttendanceModel>> getAttendancePaginated({
    String? userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _remote.getAttendancePaginated(
      userId: userId,
      limit: limit,
      startAfter: startAfter,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Stream<List<AttendanceModel>> streamTodayAttendance(String userId) {
    final query = FirebaseFirestore.instance
        .collection('attendance')
        .where('userId', isEqualTo: userId);

    return _remote.safeStream(query).map((snapshot) {
      final records = snapshot.docs
          .map(
            (doc) => AttendanceModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
      records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return records;
    });
  }

  // === Session Management ===

  @override
  Future<void> startSession(AttendanceSessionModel session) async {
    await FirebaseFirestore.instance
        .collection('attendance_sessions')
        .doc(session.id)
        .set(session.toMap());
  }

  @override
  Future<void> endSession(String sessionId) async {
    await FirebaseFirestore.instance
        .collection('attendance_sessions')
        .doc(sessionId)
        .update({
      'isActive': false,
      'endTime': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<AttendanceSessionModel?> getActiveSession() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('attendance_sessions')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AttendanceSessionModel.fromMap(
      snapshot.docs.first.data(),
      snapshot.docs.first.id,
    );
  }

  @override
  Stream<AttendanceSessionModel?> streamActiveSession() {
    final query = FirebaseFirestore.instance
        .collection('attendance_sessions')
        .where('isActive', isEqualTo: true)
        .limit(1);

    return _remote.safeStream(query).map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AttendanceSessionModel.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    });
  }

  @override
  Future<void> updateSessionQr(String sessionId, String qrSecret) async {
    await FirebaseFirestore.instance
        .collection('attendance_sessions')
        .doc(sessionId)
        .update({'qrSecret': qrSecret});
  }

  // === Analytics ===

  @override
  Future<Map<DateTime, int>> getAttendanceStats({int days = 7, String? userId}) async {
    final now = DateTime.now();
    final Map<DateTime, int> stats = {};

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      var query = FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isEqualTo: dateStr);
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
          
      final snapshot = await query.get();
      stats[date] = snapshot.docs.length;
    }

    return stats;
  }
}
