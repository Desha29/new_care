import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/di/injection.dart';
import '../../data/models/payroll_model.dart';
import 'payroll_state.dart';
import 'package:uuid/uuid.dart';

/// كيوبت الرواتب - Payroll Cubit
/// إدارة حالة شاشة الرواتب وحساب المرتبات
class PayrollCubit extends Cubit<PayrollState> {
  final FirebaseService _firebaseService;
  List<PayrollModel> _currentPayrolls = [];

  PayrollCubit()
      : _firebaseService = sl<FirebaseService>(),
        super(PayrollInitial());

  /// تحميل رواتب شهر معين - Load payroll for month
  Future<void> loadPayroll({int? year, int? month}) async {
    emit(PayrollLoading());
    try {
      final now = DateTime.now();
      final targetYear = year ?? now.year;
      final targetMonth = month ?? now.month;

      // Since we don't have a dedicated Payroll collection in FirebaseService yet,
      // we generate the payrolls on the fly by calling the calculation method.
      // This will ensure the values are always up to date.
      final payrolls = await _generateCalculatedPayrolls(targetYear, targetMonth);
      _currentPayrolls = payrolls;

      emit(PayrollLoaded(
        payrolls: _currentPayrolls,
        selectedYear: targetYear,
        selectedMonth: targetMonth,
      ));
    } catch (e) {
      emit(PayrollError('فشل تحميل الرواتب: $e'));
    }
  }

  /// Calculate salaries
  Future<List<PayrollModel>> _generateCalculatedPayrolls(int year, int month) async {
    final activeUsers = await _firebaseService.getActiveNurses();
    final allAttendances = await _firebaseService.getMonthlyAttendanceRecords(year, month);
    
    List<PayrollModel> generated = [];

    for (final user in activeUsers) {
      final userAtts = allAttendances.where((a) => a.userId == user.id).toList();
      int totalDays = userAtts.length;
      double totalHours = 0;
      
      for (final att in userAtts) {
        if (att.shiftDuration != null) {
          totalHours += att.shiftDuration!.inMinutes / 60.0;
        }
      }
      
      // Default standard rate for nurses based on business rules
      final double hourlyRate = 50.0; 
      final double baseSalary = totalHours * hourlyRate;

      generated.add(
        PayrollModel(
          id: const Uuid().v4(),
          userId: user.id,
          userName: user.name,
          year: year,
          month: month,
          totalHours: totalHours,
          hourlyRate: hourlyRate,
          baseSalary: baseSalary,
          bonus: 0,
          deductions: 0,
          netSalary: baseSalary,
          totalDays: totalDays,
          absentDays: 0,
          status: 'draft',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      );
    }
    return generated;
  }

  /// حساب رواتب الشهر - Calculate monthly payroll
  Future<void> calculateMonthlyPayroll({
    required int year,
    required int month,
  }) async {
    emit(PayrollLoading());
    try {
      final payrolls = await _generateCalculatedPayrolls(year, month);
      _currentPayrolls = payrolls;
      emit(const PayrollActionSuccess('تم حساب الرواتب بنجاح بناءً على سجلات الحضور والانصراف'));
      emit(PayrollLoaded(
        payrolls: _currentPayrolls,
        selectedYear: year,
        selectedMonth: month,
      ));
    } catch (e) {
      emit(PayrollError('فشل حساب الرواتب: $e'));
    }
  }

  /// اعتماد الراتب - Approve payroll
  Future<void> approvePayroll(String payrollId) async {
    try {
      final index = _currentPayrolls.indexWhere((p) => p.id == payrollId);
      if (index >= 0) {
        _currentPayrolls[index] = _currentPayrolls[index].copyWith(status: 'approved');
      }
      emit(const PayrollActionSuccess('تم اعتماد الراتب'));
      
      final currentState = state;
      if (currentState is PayrollLoaded) {
        emit(PayrollLoaded(
          payrolls: List.from(_currentPayrolls),
          selectedYear: currentState.selectedYear,
          selectedMonth: currentState.selectedMonth,
        ));
      }
    } catch (e) {
      emit(PayrollError('فشل اعتماد الراتب: $e'));
    }
  }

  /// تسجيل الدفع - Mark as paid
  Future<void> markAsPaid(String payrollId) async {
    try {
      final index = _currentPayrolls.indexWhere((p) => p.id == payrollId);
      if (index >= 0) {
        _currentPayrolls[index] = _currentPayrolls[index].copyWith(status: 'paid');
      }
      emit(const PayrollActionSuccess('تم تسجيل الدفع'));
      
      final currentState = state;
      if (currentState is PayrollLoaded) {
        emit(PayrollLoaded(
          payrolls: List.from(_currentPayrolls),
          selectedYear: currentState.selectedYear,
          selectedMonth: currentState.selectedMonth,
        ));
      }
    } catch (e) {
      emit(PayrollError('فشل تسجيل الدفع: $e'));
    }
  }
}
