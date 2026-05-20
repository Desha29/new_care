import 'dart:developer';
import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';
import '../models/attendance_session_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/enums/shift_role.dart';

/// تنفيذ مستودع الحضور - Firestore-first with real-time listening
/// كل العمليات تتم على Firestore مباشرة مع real-time updates
class AttendanceRepositoryImpl implements IAttendanceRepository {
  final _local = SqliteService.instance;
  final _remote = FirebaseService.instance;
  final _firestore = FirebaseFirestore.instance;

  // كاش للمستخدمين عشان نمنع قراءات متكررة من Firestore
  final Map<String, UserModel> _usersCache = {};
  DateTime? _usersCacheTime;

  @override
  Future<void> checkIn(AttendanceModel attendance) async {
    // 1. Save to Firestore directly
    await _remote.checkIn(attendance);
    // 2. Also save locally for offline backup
    try {
      await _local.insert('attendance', attendance.toSqliteMap());
    } catch (e) {
      log('[AttendanceRepo] Local backup error: $e');
    }
  }

  @override
  Future<void> checkOut(String attendanceId) async {
    // 1. Update on Firestore directly
    await _remote.checkOut(attendanceId);
    // 2. Also update locally for offline backup
    try {
      final localRecord = await _local.getById('attendance', attendanceId);
      if (localRecord != null) {
        final updated = Map<String, dynamic>.from(localRecord);
        updated['checkOutTime'] = DateTime.now().toIso8601String();
        updated['status'] = 'checked_out';
        await _local.insert('attendance', updated);
      }
    } catch (e) {
      log('[AttendanceRepo] Local backup error: $e');
    }
  }

  @override
  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    // Firestore first
    try {
      final record = await _remote.getTodayAttendance(userId);
      if (record != null) {
        return await _checkAndAutoCheckout(record);
      }
      return null;
    } catch (e) {
      log('[AttendanceRepo] Firestore error, falling back to local: $e');
      // Fallback to local if Firestore fails
      final db = await _local.database;
      final todayStr = _getTodayString();
      final results = await db.query(
        'attendance',
        where: 'userId = ? AND date = ?',
        whereArgs: [userId, todayStr],
        orderBy: 'checkInTime DESC',
        limit: 1,
      );
      if (results.isNotEmpty) {
        final record = AttendanceModel.fromMap(
          results.first,
          results.first['id'] as String,
        );
        return await _checkAndAutoCheckout(record);
      }
      return null;
    }
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
    return await _remote.getMonthlyAttendanceRecords(year, month);
  }

  @override
  Future<List<AttendanceModel>> getTodayAttendanceRecords() async {
    // Firestore first
    try {
      final todayStr = _getTodayString();
      final snapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: todayStr)
          .get();

      final List<AttendanceModel> records = [];
      for (final doc in snapshot.docs) {
        final record = AttendanceModel.fromMap(doc.data(), doc.id);
        records.add(await _checkAndAutoCheckout(record));
      }
      records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return records;
    } catch (e) {
      log('[AttendanceRepo] Firestore error, falling back to local: $e');
      // Fallback to local
      final db = await _local.database;
      final todayStr = _getTodayString();
      final results = await db.query(
        'attendance',
        where: 'date = ?',
        whereArgs: [todayStr],
      );
      final List<AttendanceModel> records = [];
      for (final m in results) {
        final record = AttendanceModel.fromMap(m, m['id'] as String);
        records.add(await _checkAndAutoCheckout(record));
      }
      return records;
    }
  }

  @override
  Stream<List<AttendanceModel>> streamTodayAttendanceRecords() {
    final today = _getTodayString();
    final query = _firestore
        .collection('attendance')
        .where('date', isEqualTo: today);

    return query.snapshots().asyncMap((snapshot) async {
      final records = snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();

      final List<AttendanceModel> processed = [];
      for (final r in records) {
        processed.add(await _checkAndAutoCheckout(r));
      }
      processed.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return processed;
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
    final today = _getTodayString();
    final query = _firestore
        .collection('attendance')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today);

    return query.snapshots().asyncMap((snapshot) async {
      final records = snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();

      final List<AttendanceModel> processed = [];
      for (final r in records) {
        processed.add(await _checkAndAutoCheckout(r));
      }
      processed.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return processed;
    });
  }

  /// جلب بيانات المستخدم من Firestore أو الكاش
  Future<UserModel?> _getUserData(String userId) async {
    // تحقق من الكاش أولاً (صالح لمدة 5 دقائق)
    if (_usersCacheTime != null &&
        DateTime.now().difference(_usersCacheTime!).inMinutes < 5 &&
        _usersCache.containsKey(userId)) {
      return _usersCache[userId];
    }

    try {
      // جلب من Firestore
      final user = await _remote.getUser(userId);
      if (user != null) {
        _usersCache[userId] = user;
        _usersCacheTime = DateTime.now();
      }
      return user;
    } catch (e) {
      // Fallback to local SQLite
      try {
        final localRecord = await _local.getUser(userId);
        if (localRecord != null) {
          return UserModel.fromSqliteMap(localRecord);
        }
      } catch (_) {}
      return null;
    }
  }

  /// يتحقق مما إذا كان الموظف قد أكمل ساعات عمله اليومية المخصصة ليقوم بالانصراف تلقائياً
  /// Auto-checkout: checks if nurse exceeded dailyWorkHours and auto checks them out
  Future<AttendanceModel> _checkAndAutoCheckout(AttendanceModel record) async {
    if (!record.isCheckedIn) return record;

    final user = await _getUserData(record.userId);
    if (user == null) return record;

    final elapsedHours =
        DateTime.now().difference(record.checkInTime).inMinutes / 60.0;

    if (elapsedHours >= user.dailyWorkHours) {
      final checkoutTime = record.checkInTime.add(
        Duration(minutes: (user.dailyWorkHours * 60).round()),
      );

      int earlyLeave = 0;
      if (checkoutTime.hour < 16) {
        earlyLeave = (16 - checkoutTime.hour) * 60 - checkoutTime.minute;
      }

      final updated = record.copyWith(
        checkOutTime: checkoutTime,
        status: AttendanceStatus.checkedOut,
        earlyLeaveMinutes: earlyLeave,
      );

      // 1. Update on Firestore directly
      try {
        await _firestore.collection('attendance').doc(record.id).update({
          'checkOutTime': checkoutTime.toIso8601String(),
          'status': 'checked_out',
          'earlyLeaveMinutes': earlyLeave,
        });
        log(
          '[AttendanceRepo] ✓ Auto-checkout for ${record.userName} after ${user.dailyWorkHours}h',
        );
      } catch (e) {
        log('[AttendanceRepo] Auto-checkout Firestore error: $e');
      }

      // 2. Also update locally for backup
      try {
        await _local.insert('attendance', updated.toSqliteMap());
      } catch (e) {
        log('[AttendanceRepo] Auto-checkout local error: $e');
      }

      return updated;
    }

    return record;
  }

  // === Session Management ===

  @override
  Future<void> startSession(AttendanceSessionModel session) async {
    await _firestore
        .collection('attendance_sessions')
        .doc(session.id)
        .set(session.toMap());
  }

  @override
  Future<void> endSession(String sessionId) async {
    await _firestore.collection('attendance_sessions').doc(sessionId).update({
      'isActive': false,
      'endTime': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<AttendanceSessionModel?> getActiveSession() async {
    final snapshot = await _firestore
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
    final query = _firestore
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
    await _firestore.collection('attendance_sessions').doc(sessionId).update({
      'qrSecret': qrSecret,
    });
  }

  // === Analytics ===

  @override
  Future<Map<DateTime, int>> getAttendanceStats({
    int days = 7,
    String? userId,
  }) async {
    final now = DateTime.now();
    final Map<DateTime, int> stats = {};

    for (int i = 0; i < days; i++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      var query = _firestore
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

  @override
  Future<void> deleteAttendance(String id) async {
    try {
      await _firestore.collection('attendance').doc(id).delete();
      log('[AttendanceRepo] ✓ Deleted attendance record $id from Firestore');
    } catch (e) {
      log('[AttendanceRepo] Error deleting attendance record: $e');
      rethrow;
    }
  }
}
