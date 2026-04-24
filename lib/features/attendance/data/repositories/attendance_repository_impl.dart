import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase/firebase_base.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

/// تنفيذ مستودع الحضور والانصراف - Attendance Repository Implementation
class AttendanceRepositoryImpl extends FirebaseBase implements IAttendanceRepository {
  CollectionReference get _attendanceRef =>
      firestore.collection('attendance');

  @override
  Future<void> checkIn(AttendanceModel attendance) async {
    await _attendanceRef.doc(attendance.id).set(attendance.toMap());
  }

  @override
  Future<void> checkOut(String attendanceId) async {
    await _attendanceRef.doc(attendanceId).update({
      'checkOutTime': DateTime.now().toIso8601String(),
      'status': 'checked_out',
    });
  }

  @override
  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    final today = todayString();
    final snapshot = await _attendanceRef
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today)
        .orderBy('checkInTime', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AttendanceModel.fromMap(
      snapshot.docs.first.data() as Map<String, dynamic>,
      snapshot.docs.first.id,
    );
  }

  @override
  Future<bool> isCheckedInToday(String userId) async {
    final attendance = await getTodayAttendance(userId);
    return attendance != null && attendance.isCheckedIn;
  }

  @override
  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(int year, int month) async {
    final startId = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final endId = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    final snapshot = await _attendanceRef
        .where('date', isGreaterThanOrEqualTo: startId)
        .where('date', isLessThan: endId)
        .get();
    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<List<AttendanceModel>> getTodayAttendanceRecords() async {
    final today = todayString();
    final snapshot = await _attendanceRef.where('date', isEqualTo: today).get();
    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<List<AttendanceModel>> getUserAttendance(String userId, {int limit = 30}) async {
    final snapshot = await _attendanceRef
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Stream<List<AttendanceModel>> streamTodayAttendanceRecords() {
    final todayStr = todayString();
    return safeStream(_attendanceRef.where('date', isEqualTo: todayStr)).map(
      (snapshot) => snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }

  @override
  Stream<AttendanceModel?> streamTodayAttendance(String userId) {
    final today = todayString();
    return safeStream(
      _attendanceRef
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: today)
          .orderBy('checkInTime', descending: true)
          .limit(1),
    ).map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AttendanceModel.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    });
  }
}
