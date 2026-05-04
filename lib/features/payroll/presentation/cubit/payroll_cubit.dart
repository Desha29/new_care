import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/case_status.dart';
import '../../../../core/services/notifications/case_change_notifier.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../../data/models/payroll_model.dart';
import 'payroll_state.dart';
import 'package:uuid/uuid.dart';

/// كيوبت الرواتب - Payroll Cubit
/// إدارة حالة شاشة الرواتب وحساب المرتبات
/// يعمل محلياً أولاً ويحفظ في SQLite - Local-first with SQLite persistence
class PayrollCubit extends Cubit<PayrollState> {
  final IPayrollRepository _payrollRepository;
  List<PayrollModel> _currentPayrolls = [];
  StreamSubscription? _caseChangeSubscription;

  /// عدد ساعات العمل اليومية المتوقعة - Expected daily work hours
  static const double _expectedDailyHours = 8.0;

  /// عدد أيام العمل في الشهر - Expected working days per month
  static const int _expectedMonthlyDays = 26;

  /// معامل الساعات الإضافية - Overtime multiplier
  static const double _overtimeMultiplier = 1.5;

  /// مبلغ العملية الخارجية - Outside case fee (EGP)
  static const double _outsideCaseFee = 15.0;

  PayrollCubit({required IPayrollRepository payrollRepository})
    : _payrollRepository = payrollRepository,
      super(PayrollInitial()) {
    _setupCaseChangeListener();
  }

  /// Listen to case changes and reload payroll automatically
  void _setupCaseChangeListener() {
    _caseChangeSubscription = CaseChangeNotifier().onCaseChanged.listen((
      event,
    ) {
      // Reload payroll when any case is added, updated, or deleted
      if (state is PayrollLoaded) {
        final currentState = state as PayrollLoaded;
        loadPayroll(
          year: currentState.selectedYear,
          month: currentState.selectedMonth,
          force: true,
        );
      }
    });
  }

  @override
  Future<void> close() {
    _caseChangeSubscription?.cancel();
    return super.close();
  }

  /// تحميل رواتب شهر معين - Load payroll for month
  /// يحمل أولاً من SQLite، وإذا لم يوجد يحسب من البيانات
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
      // 1. محاولة تحميل من SQLite أولاً
      final savedPayrolls = await _payrollRepository.getPayrolls(
        targetYear,
        targetMonth,
      );

      if (savedPayrolls.isNotEmpty && !force) {
        _currentPayrolls = savedPayrolls;
      } else {
        // 2. إذا لم يوجد أو force، نحسب من البيانات
        final payrolls = await _generateCalculatedPayrolls(
          targetYear,
          targetMonth,
        );
        _currentPayrolls = payrolls;

        // 3. حفظ النتائج محلياً
        if (payrolls.isNotEmpty) {
          // حذف القديم أولاً ثم حفظ الجديد
          for (final old in savedPayrolls) {
            await _payrollRepository.deletePayroll(old.id);
          }
          await _payrollRepository.savePayrollBatch(payrolls);
        }
      }

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

  /// حساب الرواتب مع منطق محسّن - Enhanced payroll calculation
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
      // === حساب ساعات العمل من سجلات الحضور ===
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

      // === الراتب الأساسي (ثابت من ملف المستخدم) ===
      final double baseSalary = user.salary;

      // === حساب سعر الساعة ===
      // سعر الساعة = الراتب الأساسي / (أيام العمل المتوقعة × ساعات اليوم)
      final double expectedMonthlyHours = _expectedMonthlyDays * _expectedDailyHours;
      final double hourlyRate = baseSalary / expectedMonthlyHours;

      // === حساب الساعات المتوقعة بناءً على أيام الحضور الفعلية ===
      final double expectedHoursForAttendedDays = totalDays * _expectedDailyHours;

      // === حساب الساعات الإضافية (Overtime) ===
      double overtimeHours = 0;
      double overtimeAmount = 0;
      if (totalHours > expectedHoursForAttendedDays && expectedHoursForAttendedDays > 0) {
        overtimeHours = totalHours - expectedHoursForAttendedDays;
        overtimeAmount = overtimeHours * hourlyRate * _overtimeMultiplier;
      }

      // === حساب الخصومات (ساعات ناقصة) ===
      double deductions = 0;
      if (totalHours < expectedHoursForAttendedDays && expectedHoursForAttendedDays > 0) {
        final missedHours = expectedHoursForAttendedDays - totalHours;
        deductions = missedHours * hourlyRate;
      }

      // === حساب أيام الغياب ===
      final int absentDays = (_expectedMonthlyDays - totalDays).clamp(0, _expectedMonthlyDays);

      // === حساب مكافأة العمليات الخارجية ===
      final outsideCasesCount = allCases
          .where(
            (c) => c.nurseId == user.id && c.caseType == CaseType.homeVisit,
          )
          .length;
      final double outsideCasesFees = outsideCasesCount * _outsideCaseFee;

      // === حساب صافي الراتب ===
      // الصافي = الأساسي + العمليات الخارجية + الإضافي - الخصومات
      final double netSalary = baseSalary + outsideCasesFees + overtimeAmount - deductions;

      generated.add(
        PayrollModel(
          id: const Uuid().v4(),
          userId: user.id,
          userName: user.name,
          year: year,
          month: month,
          totalHours: double.parse(totalHours.toStringAsFixed(2)),
          hourlyRate: double.parse(hourlyRate.toStringAsFixed(2)),
          baseSalary: baseSalary,
          bonus: overtimeAmount, // نستخدم حقل bonus للساعات الإضافية
          outsideCasesFees: outsideCasesFees,
          deductions: double.parse(deductions.toStringAsFixed(2)),
          netSalary: double.parse(netSalary.toStringAsFixed(2)),
          totalDays: totalDays,
          absentDays: absentDays,
          status: 'draft',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
    return generated;
  }

  /// حساب رواتب الشهر (إعادة حساب إجبارية) - Force recalculate monthly payroll
  Future<void> calculateMonthlyPayroll({
    required int year,
    required int month,
  }) async {
    emit(PayrollLoading());
    try {
      // حذف الرواتب القديمة لهذا الشهر
      final oldPayrolls = await _payrollRepository.getPayrolls(year, month);
      for (final old in oldPayrolls) {
        await _payrollRepository.deletePayroll(old.id);
      }

      // إعادة الحساب
      final payrolls = await _generateCalculatedPayrolls(year, month);
      _currentPayrolls = payrolls;

      // حفظ محلياً + طابور المزامنة
      if (payrolls.isNotEmpty) {
        await _payrollRepository.savePayrollBatch(payrolls);
      }

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
      await _payrollRepository.updatePayrollStatus(payrollId, 'approved');

      final index = _currentPayrolls.indexWhere((p) => p.id == payrollId);
      if (index >= 0) {
        _currentPayrolls[index] = _currentPayrolls[index].copyWith(
          status: 'approved',
          updatedAt: DateTime.now(),
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
      await _payrollRepository.updatePayrollStatus(payrollId, 'paid');

      final index = _currentPayrolls.indexWhere((p) => p.id == payrollId);
      if (index >= 0) {
        _currentPayrolls[index] = _currentPayrolls[index].copyWith(
          status: 'paid',
          updatedAt: DateTime.now(),
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
