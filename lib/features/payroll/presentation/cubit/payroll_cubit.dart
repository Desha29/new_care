import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/case_status.dart';
import '../../../../core/services/notifications/case_change_notifier.dart';
import '../../../../core/services/notifications/data_change_notifier.dart';
import '../../../cases/data/models/case_model.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../../data/models/payroll_model.dart';
import '../../data/models/advance_model.dart';
import 'payroll_state.dart';
import 'package:uuid/uuid.dart';

/// كيوبت الرواتب - Payroll Cubit
/// إدارة حالة شاشة الرواتب وحساب المرتبات
/// يعمل محلياً أولاً ويحفظ في SQLite - Local-first with SQLite persistence
class PayrollCubit extends Cubit<PayrollState> {
  final IPayrollRepository _payrollRepository;
  List<PayrollModel> _currentPayrolls = [];
  StreamSubscription? _caseChangeSubscription;
  StreamSubscription? _dataChangeSubscription;

  /// عدد ساعات العمل اليومية المتوقعة - Expected daily work hours
  static const double _expectedDailyHours = 8.0;

  /// عدد أيام العمل في الشهر - Expected working days per month
  static const int _expectedMonthlyDays = 26;

  /// معامل الساعات الإضافية - Overtime multiplier
  static const double _overtimeMultiplier = 1.5;

  PayrollCubit({required IPayrollRepository payrollRepository})
    : _payrollRepository = payrollRepository,
      super(PayrollInitial()) {
    _setupCaseChangeListener();
    _setupDataChangeListener();
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

  /// Listen to data changes (user salary updates, etc.) and reload payroll
  void _setupDataChangeListener() {
    _dataChangeSubscription = DataChangeNotifier().onDataChanged.listen((
      event,
    ) {
      // إعادة حساب الرواتب عند تغيير بيانات المستخدم (مثل المرتب)
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
    _dataChangeSubscription?.cancel();
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
      // 1. قراءة الرواتب المحفوظة لهذا الشهر أولاً
      final savedPayrolls = await _payrollRepository.getPayrolls(
        targetYear,
        targetMonth,
      );

      if (savedPayrolls.isNotEmpty && !force) {
        _currentPayrolls = savedPayrolls;
        emit(
          PayrollLoaded(
            payrolls: _currentPayrolls,
            selectedYear: targetYear,
            selectedMonth: targetMonth,
          ),
        );
        return;
      }

      // خلاف ذلك، نقوم بحذف القديم وإعادة الحساب
      for (final old in savedPayrolls) {
        await _payrollRepository.deletePayroll(old.id);
      }

      // 2. إعادة الحساب من البيانات الفعلية
      final payrolls = await _generateCalculatedPayrolls(
        targetYear,
        targetMonth,
      );
      _currentPayrolls = payrolls;

      // 3. حفظ النتائج محلياً
      if (payrolls.isNotEmpty) {
        await _payrollRepository.savePayrollBatch(payrolls);
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
    final allAdvances = await _payrollRepository.getMonthlyAdvances(year, month);

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
      final double expectedMonthlyHours =
          _expectedMonthlyDays * _expectedDailyHours;
      final double hourlyRate = baseSalary / expectedMonthlyHours;

      // === حساب الساعات المتوقعة بناءً على أيام الحضور الفعلية ===
      final double expectedHoursForAttendedDays =
          totalDays * _expectedDailyHours;

      // === حساب الساعات الإضافية (Overtime) ===
      double overtimeHours = 0;
      double overtimeAmount = 0;
      if (totalHours > expectedHoursForAttendedDays &&
          expectedHoursForAttendedDays > 0) {
        overtimeHours = totalHours - expectedHoursForAttendedDays;
        overtimeAmount = overtimeHours * hourlyRate * _overtimeMultiplier;
      }

      // === حساب الخصومات (ساعات ناقصة) ===
      double deductions = 0;
      if (totalHours < expectedHoursForAttendedDays &&
          expectedHoursForAttendedDays > 0) {
        final missedHours = expectedHoursForAttendedDays - totalHours;
        deductions = missedHours * hourlyRate;
      }

      // === حساب أيام الغياب ===
      final int absentDays = (_expectedMonthlyDays - totalDays).clamp(
        0,
        _expectedMonthlyDays,
      );

      final outsideCasesCount = allCases
          .where(
            (c) => c.nurseId == user.id && c.caseType == CaseType.homeVisit,
          )
          .length;
      final currentFee = await _payrollRepository.getOutsideCaseFee();
      final double outsideCasesFees = outsideCasesCount * currentFee;

      // === حساب إجمالي السلف لهذا الموظف ===
      final userAdvances = allAdvances.where((a) => a.userId == user.id).toList();
      final double totalSalafa = userAdvances.fold(0.0, (sum, a) => sum + a.amount);

      // === حساب صافي الراتب ===
      // الصافي = الأساسي + العمليات الخارجية + الإضافي - الخصومات - السلف
      final double netSalary =
          baseSalary + outsideCasesFees + overtimeAmount - deductions - totalSalafa;

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
          salafa: double.parse(totalSalafa.toStringAsFixed(2)),
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
      final previousState = state;
      emit(const PayrollActionSuccess('تم اعتماد الراتب'));

      if (previousState is PayrollLoaded) {
        emit(
          PayrollLoaded(
            payrolls: List.from(_currentPayrolls),
            selectedYear: previousState.selectedYear,
            selectedMonth: previousState.selectedMonth,
          ),
        );
      }
    } catch (e) {
      emit(PayrollError('فشل اعتماد الراتب: $e'));
    }
  }

  /// اعتماد كافة الرواتب للشهر الحالي - Approve all payrolls for the month
  Future<void> approveAllPayrolls() async {
    final currentState = state;
    if (currentState is! PayrollLoaded || currentState.payrolls.isEmpty) return;

    emit(PayrollLoading());
    try {
      for (final payroll in currentState.payrolls) {
        if (payroll.status == 'draft') {
          await _payrollRepository.updatePayrollStatus(payroll.id, 'approved');
        }
      }

      // إعادة تحميل البيانات لضمان المزامنة
      await loadPayroll(
        year: currentState.selectedYear,
        month: currentState.selectedMonth,
        force: true,
      );

      emit(const PayrollActionSuccess('تم اعتماد كافة رواتب الشهر بنجاح'));
      
      // Re-emit loaded state from current _currentPayrolls
      emit(
        PayrollLoaded(
          payrolls: List.from(_currentPayrolls),
          selectedYear: currentState.selectedYear,
          selectedMonth: currentState.selectedMonth,
        ),
      );
    } catch (e) {
      emit(PayrollError('فشل اعتماد الرواتب: $e'));
      // استعادة الحالة السابقة
      emit(currentState);
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
      final previousState = state;
      emit(const PayrollActionSuccess('تم تسجيل الدفع'));

      if (previousState is PayrollLoaded) {
        emit(
          PayrollLoaded(
            payrolls: List.from(_currentPayrolls),
            selectedYear: previousState.selectedYear,
            selectedMonth: previousState.selectedMonth,
          ),
        );
      }
    } catch (e) {
      emit(PayrollError('فشل تسجيل الدفع: $e'));
    }
  }

  /// جلب الحالات الشهرية - Get monthly cases (Public helper)
  Future<List<CaseModel>> getMonthlyCases(int year, int month) async {
    return _payrollRepository.getMonthlyCases(year, month);
  }

  /// تحديث المكافآت والخصومات والسلف يدوياً - Update rewards, deductions and advances manually
  Future<void> updatePayrollExtras({
    required String payrollId,
    double? bonus,
    double? deductions,
    double? salafa,
    String? notes,
  }) async {
    try {
      final index = _currentPayrolls.indexWhere((p) => p.id == payrollId);
      if (index >= 0) {
        final current = _currentPayrolls[index];
        final updated = current.copyWith(
          bonus: bonus ?? current.bonus,
          deductions: deductions ?? current.deductions,
          salafa: salafa ?? current.salafa,
          notes: notes ?? current.notes,
        );

        final fullyUpdated = updated.copyWith(
          netSalary: double.parse(updated.calculatedNetSalary.toStringAsFixed(2)),
          updatedAt: DateTime.now(),
        );

        await _payrollRepository.updatePayroll(fullyUpdated);
        _currentPayrolls[index] = fullyUpdated;

        final previousState = state;
        emit(const PayrollActionSuccess('تم تحديث تفاصيل الراتب بنجاح'));

        if (previousState is PayrollLoaded) {
          emit(
            PayrollLoaded(
              payrolls: List.from(_currentPayrolls),
              selectedYear: previousState.selectedYear,
              selectedMonth: previousState.selectedMonth,
            ),
          );
        }
      }
    } catch (e) {
      emit(PayrollError('فشل تحديث البيانات: $e'));
    }
  }

  // === عمليات السلف - Advance Operations ===

  /// جلب سلف موظف لشهر معين - Get advances for a specific payroll
  Future<List<AdvanceModel>> getAdvancesForPayroll(String userId, int year, int month) async {
    return _payrollRepository.getMonthlyAdvancesForUser(userId, year, month);
  }

  /// إضافة سلفة جديدة - Add a new advance
  Future<void> addAdvance({
    required String userId,
    required String userName,
    required double amount,
    required DateTime date,
    String notes = '',
    String createdBy = '',
  }) async {
    try {
      final advance = AdvanceModel(
        id: const Uuid().v4(),
        userId: userId,
        userName: userName,
        amount: amount,
        date: date,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: createdBy,
      );

      await _payrollRepository.saveAdvance(advance);

      // إعادة حساب سلفة الموظف في الراتب - Recalculate the user's salafa in payroll
      await _recalculateUserSalafa(userId);

      emit(const PayrollActionSuccess('تم إضافة السلفة بنجاح'));
      _emitCurrentLoaded();
    } catch (e) {
      emit(PayrollError('فشل إضافة السلفة: $e'));
    }
  }

  /// حذف سلفة - Delete an advance
  Future<void> deleteAdvanceRecord(String advanceId, String userId) async {
    try {
      await _payrollRepository.deleteAdvance(advanceId);

      // إعادة حساب سلفة الموظف في الراتب - Recalculate the user's salafa in payroll
      await _recalculateUserSalafa(userId);

      emit(const PayrollActionSuccess('تم حذف السلفة بنجاح'));
      _emitCurrentLoaded();
    } catch (e) {
      emit(PayrollError('فشل حذف السلفة: $e'));
    }
  }

  /// إعادة حساب إجمالي السلف لموظف معين وتحديث الراتب
  Future<void> _recalculateUserSalafa(String userId) async {
    final previousState = state;
    if (previousState is! PayrollLoaded) return;

    final year = previousState.selectedYear;
    final month = previousState.selectedMonth;

    final advances = await _payrollRepository.getMonthlyAdvancesForUser(userId, year, month);
    final totalSalafa = advances.fold(0.0, (sum, a) => sum + a.amount);

    final index = _currentPayrolls.indexWhere((p) => p.userId == userId);
    if (index >= 0) {
      final current = _currentPayrolls[index];
      final updated = current.copyWith(
        salafa: double.parse(totalSalafa.toStringAsFixed(2)),
      );
      final fullyUpdated = updated.copyWith(
        netSalary: double.parse(updated.calculatedNetSalary.toStringAsFixed(2)),
        updatedAt: DateTime.now(),
      );
      await _payrollRepository.updatePayroll(fullyUpdated);
      _currentPayrolls[index] = fullyUpdated;
    }
  }

  /// إصدار حالة التحميل الحالية - Emit current loaded state
  void _emitCurrentLoaded() {
    final previousState = state;
    if (previousState is PayrollLoaded) {
      emit(
        PayrollLoaded(
          payrolls: List.from(_currentPayrolls),
          selectedYear: previousState.selectedYear,
          selectedMonth: previousState.selectedMonth,
        ),
      );
    }
  }
}
