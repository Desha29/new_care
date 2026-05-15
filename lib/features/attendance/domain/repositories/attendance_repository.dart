import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firebase/firebase_service.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/attendance_session_model.dart';

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
  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(
    int year,
    int month,
  );

  /// جلب جميع سجلات حضور اليوم - Get all today's attendance
  Future<List<AttendanceModel>> getTodayAttendanceRecords();

  /// جلب سجلات الحضور بصفحات - Get paginated attendance records
  Future<PaginatedResult<AttendanceModel>> getAttendancePaginated({
    String? userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// بث سجلات حضور اليوم - Stream today's attendance records
  Stream<List<AttendanceModel>> streamTodayAttendanceRecords();

  /// بث حالة حضور مستخدم معين لليوم - Stream user's today attendance
  Stream<List<AttendanceModel>> streamTodayAttendance(String userId);

  // === Session Management ===

  /// بدء جلسة حضور جديدة - Start a new attendance session
  Future<void> startSession(AttendanceSessionModel session);

  /// إنهاء جلسة حضور - End an attendance session
  Future<void> endSession(String sessionId);

  /// جلب الجلسة النشطة الحالية - Get current active session
  Future<AttendanceSessionModel?> getActiveSession();

  /// بث الجلسة النشطة - Stream active session
  Stream<AttendanceSessionModel?> streamActiveSession();

  /// تحديث رمز QR للجلسة - Update session QR secret
  Future<void> updateSessionQr(String sessionId, String qrSecret);

  // === Analytics ===

  /// جلب إحصائيات الحضور للأيام الأخيرة - Get attendance stats for last X days
  Future<Map<DateTime, int>> getAttendanceStats({int days = 7, String? userId});
}
