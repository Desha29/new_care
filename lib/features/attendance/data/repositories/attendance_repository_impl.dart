import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';
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
  Future<List<AttendanceModel>> getUserAttendance(
    String userId, {
    int limit = 30,
  }) async {
    final db = await _local.database;
    final results = await db.query(
      'attendance',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: limit,
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
              doc.data() as Map<String, dynamic>,
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
}
