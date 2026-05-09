import '../../../auth/data/models/user_model.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../cases/data/models/case_model.dart';
import '../../data/models/payroll_model.dart';


/// واجهة مستودع الرواتب - Payroll Repository Interface
abstract class IPayrollRepository {
  /// جلب الموظفين النشطين - Get active staff
  Future<List<UserModel>> getActiveStaff();

  /// جلب سجلات الحضور الشهرية - Get monthly attendance records
  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(int year, int month);

  /// جلب الحالات الشهرية - Get monthly cases
  Future<List<CaseModel>> getMonthlyCases(int year, int month);

  /// حفظ سجل راتب (محلي + طابور مزامنة) - Save payroll record
  Future<void> savePayroll(PayrollModel payroll, {bool isNew = true});

  /// حفظ مجموعة سجلات رواتب - Save batch of payroll records
  Future<void> savePayrollBatch(List<PayrollModel> payrolls);

  /// جلب رواتب شهر معين من SQLite - Get payrolls for a month
  Future<List<PayrollModel>> getPayrolls(int year, int month);

  /// تحديث حالة الراتب - Update payroll status
  Future<void> updatePayrollStatus(String payrollId, String status);

  /// حذف سجل راتب - Delete payroll record
  Future<void> deletePayroll(String payrollId);

  /// جلب مبلغ العملية الخارجية - Get outside case fee
  Future<double> getOutsideCaseFee();

  /// تحديث سجل راتب بالكامل - Update full payroll record
  Future<void> updatePayroll(PayrollModel payroll);
}
