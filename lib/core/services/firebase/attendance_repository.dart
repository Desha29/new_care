import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/attendance/data/models/attendance_model.dart';
import 'firebase_base.dart';

/// مستودع الحضور والانصراف - Attendance Repository
class AttendanceRepository extends FirebaseBase {
  CollectionReference get _attendanceRef =>
      firestore.collection('attendance');

  /// تسجيل حضور - Check in
  Future<void> checkIn(AttendanceModel attendance) async {
    await _attendanceRef.doc(attendance.id).set(attendance.toMap());
  }

  /// تسجيل انصراف - Check out
  Future<void> checkOut(String attendanceId) async {
    await _attendanceRef.doc(attendanceId).update({
      'checkOutTime': DateTime.now().toIso8601String(),
      'status': 'checked_out',
    });
  }

  /// جلب حضور اليوم للمستخدم - Get today's attendance for user
  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    final today = todayString();
    final snapshot = await _attendanceRef
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AttendanceModel.fromMap(
      snapshot.docs.first.data() as Map<String, dynamic>,
      snapshot.docs.first.id,
    );
  }

  /// هل المستخدم سجل حضوره اليوم؟
  Future<bool> isCheckedInToday(String userId) async {
    final attendance = await getTodayAttendance(userId);
    return attendance != null && attendance.isCheckedIn;
  }

  /// جلب جميع سجلات حضور شهر معين
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

  /// جلب جميع سجلات حضور اليوم - Get all today's attendance
  Future<List<AttendanceModel>> getTodayAttendanceRecords() async {
    final today = todayString();
    final snapshot = await _attendanceRef
        .where('date', isEqualTo: today)
        .get();
    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب سجلات حضور مستخدم - Get user attendance history
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

  /// بث حضور اليوم - Stream today's attendance
  Stream<List<AttendanceModel>> streamTodayAttendance() {
    final today = todayString();
    return _attendanceRef
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
