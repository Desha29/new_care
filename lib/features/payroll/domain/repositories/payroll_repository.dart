import '../../../auth/data/models/user_model.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../cases/data/models/case_model.dart';


/// واجهة مستودع الرواتب - Payroll Repository Interface
abstract class IPayrollRepository {
  /// جلب الموظفين النشطين - Get active staff
  Future<List<UserModel>> getActiveStaff();

  /// جلب سجلات الحضور الشهرية - Get monthly attendance records
  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(int year, int month);

  /// جلب الحالات الشهرية - Get monthly cases
  Future<List<CaseModel>> getMonthlyCases(int year, int month);
}
