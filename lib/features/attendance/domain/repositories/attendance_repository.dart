import '../../data/models/attendance_model.dart';

/// واجهة مستودع الحضور والانصراف - Attendance Repository Interface
abstract class IAttendanceRepository {
  /// تسجيل حضور - Check in
  Future<void> checkIn(AttendanceModel attendance);

  /// تسجيل انصراف - Check out
  Future<void> checkOut(String attendanceId);

  /// جلب حضور اليوم للمستخدم - Get today's attendance for user
  Future<AttendanceModel?> getTodayAttendance(String userId);

  /// هل المستخدم سجل حضوره اليوم؟ - Is user checked in today?
  Future<bool> isCheckedInToday(String userId);

  /// جلب جميع سجلات حضور شهر معين - Get monthly attendance records
  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(int year, int month);

  /// جلب جميع سجلات حضور اليوم - Get all today's attendance
  Future<List<AttendanceModel>> getTodayAttendanceRecords();

  /// جلب سجلات حضور مستخدم - Get user attendance history
  Future<List<AttendanceModel>> getUserAttendance(String userId, {int limit = 30});

  /// بث سجلات حضور اليوم - Stream today's attendance records
  Stream<List<AttendanceModel>> streamTodayAttendanceRecords();

  /// بث حالة حضور مستخدم معين لليوم - Stream user's today attendance
  Stream<List<AttendanceModel>> streamTodayAttendance(String userId);
}
