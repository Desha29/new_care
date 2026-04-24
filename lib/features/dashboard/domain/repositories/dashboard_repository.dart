import '../../../cases/data/models/case_model.dart';
import '../../../attendance/data/models/attendance_model.dart';

/// واجهة مستودع لوحة التحكم - Dashboard Repository Interface
abstract class IDashboardRepository {
  /// إحصائيات لوحة التحكم العامة - General Dashboard stats
  Future<Map<String, dynamic>> getDashboardStats({DateTime? date});

  /// إحصائيات الممرض - Nurse dashboard stats
  Future<Map<String, dynamic>> getNurseDashboardStats(String nurseId, {DateTime? date});

  /// بيانات الرسم البياني للأسبوع - Weekly chart data
  Future<Map<String, List<double>>> getDashboardChartData();

  /// قائمة الحالات الأخيرة - Recent cases
  Future<List<CaseModel>> getRecentCases(int limit);

  /// الموظفون الحاضرون حالياً - Active staff
  Future<List<AttendanceModel>> getActiveStaff();
}
