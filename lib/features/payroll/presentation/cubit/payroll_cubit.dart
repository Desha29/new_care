import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/case_status.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../../data/models/payroll_model.dart';
import 'payroll_state.dart';
import 'package:uuid/uuid.dart';

/// كيوبت الرواتب - Payroll Cubit
/// إدارة حالة شاشة الرواتب وحساب المرتبات
class PayrollCubit extends Cubit<PayrollState> {
  final IPayrollRepository _payrollRepository;
  List<PayrollModel> _currentPayrolls = [];

  PayrollCubit({required IPayrollRepository payrollRepository})
    : _payrollRepository = payrollRepository,
      super(PayrollInitial());

  /// تحميل رواتب شهر معين - Load payroll for month
  Future<void> loadPayroll({int? year, int? month, bool force = false}) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    if (!force && state is PayrollLoaded) {
      final s = state as PayrollLoaded;
      if (s.selectedYear == targetYear && s.selectedMonth == targetMonth) {
        return;
      }
    }

    emit(PayrollLoading());
    try {
      final payrolls = await _generateCalculatedPayrolls(
        targetYear,
        targetMonth,
      );
      _currentPayrolls = payrolls;

      emit(
        PayrollLoaded(
          payrolls: _currentPayrolls,
          selectedYear: targetYear,
          selectedMonth: targetMonth,
        ),
      );
    } catch (e) {
      emit(PayrollError('فشل تحميل الرواتب: $e'));
    }
  }

  Future<List<PayrollModel>> _generateCalculatedPayrolls(
    int year,
    int month,
  ) async {
    final activeUsers = await _payrollRepository.getActiveStaff();
    final allAttendances = await _payrollRepository.getMonthlyAttendanceRecords(
      year,
      month,
    );
    final allCases = await _payrollRepository.getMonthlyCases(year, month);

    List<PayrollModel> generated = [];

    for (final user in activeUsers) {
      final userAtts = allAttendances
          .where((a) => a.userId == user.id)
          .toList();
      int totalDays = userAtts.length;
      double totalHours = 0;

      for (final att in userAtts) {
        if (att.shiftDuration != null) {
          totalHours += att.shiftDuration!.inMinutes / 60.0;
        }
      }

      // Fixed salary from user model
      final double baseSalary = user.salary;

      // Calculate outside cases bonus (15 EGP per case)
      final outsideCasesCount = allCases
          .where(
            (c) => c.nurseId == user.id && c.caseType == CaseType.homeVisit,
          )
          .length;
      final double bonus = outsideCasesCount * 15.0;

      // Calculate deductions if hours are less than expected (e.g., 8 hours per attendance day)
      final expectedHours = totalDays * 8.0;
      double deductions = 0;

      if (totalHours < expectedHours && expectedHours > 0) {
        final missedHours = expectedHours - totalHours;
        // Hourly rate calculated based on base salary for a standard 208-hour month (26 days * 8 hours)
        final hourlyRateForDeduction = baseSalary / 208.0;
        deductions = missedHours * hourlyRateForDeduction;
      }

      generated.add(
        PayrollModel(
          id: const Uuid().v4(),
          userId: user.id,
          userName: user.name,
          year: year,
          month: month,
          totalHours: totalHours,
          hourlyRate: baseSalary / 208.0, // Visual reference
          baseSalary: baseSalary,
          bonus: 0,
          outsideCasesFees: bonus,
          deductions: deductions,
          netSalary: baseSalary + bonus - deductions,
          totalDays: totalDays,
          absentDays: 0,
          status: 'draft',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
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
      emit(
        const PayrollActionSuccess(
          'تم حساب الرواتب بنجاح بناءً على سجلات الحضور والانصراف',
        ),
      );
      emit(
        PayrollLoaded(
          payrolls: _currentPayrolls,
          selectedYear: year,
          selectedMonth: month,
        ),
      );
    } catch (e) {
      emit(PayrollError('فشل حساب الرواتب: $e'));
    }
  }

  /// اعتماد الراتب - Approve payroll
  Future<void> approvePayroll(String payrollId) async {
    try {
      final index = _currentPayrolls.indexWhere((p) => p.id == payrollId);
      if (index >= 0) {
        _currentPayrolls[index] = _currentPayrolls[index].copyWith(
          status: 'approved',
        );
      }
      emit(const PayrollActionSuccess('تم اعتماد الراتب'));

      final currentState = state;
      if (currentState is PayrollLoaded) {
        emit(
          PayrollLoaded(
            payrolls: List.from(_currentPayrolls),
            selectedYear: currentState.selectedYear,
            selectedMonth: currentState.selectedMonth,
          ),
        );
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
        _currentPayrolls[index] = _currentPayrolls[index].copyWith(
          status: 'paid',
        );
      }
      emit(const PayrollActionSuccess('تم تسجيل الدفع'));

      final currentState = state;
      if (currentState is PayrollLoaded) {
        emit(
          PayrollLoaded(
            payrolls: List.from(_currentPayrolls),
            selectedYear: currentState.selectedYear,
            selectedMonth: currentState.selectedMonth,
          ),
        );
      }
    } catch (e) {
      emit(PayrollError('فشل تسجيل الدفع: $e'));
    }
  }
}
