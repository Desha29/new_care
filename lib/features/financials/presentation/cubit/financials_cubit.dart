import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/network/connectivity_service.dart';
import '../../../../core/services/notifications/case_change_notifier.dart';
import '../../domain/repositories/financials_repository.dart';
import '../../../cases/data/models/case_model.dart';
import '../../data/models/expense_model.dart';

part 'financials_state.dart';

class FinancialsCubit extends Cubit<FinancialsState> {
  final IFinancialsRepository _financialsRepository;
  StreamSubscription? _caseChangeSubscription;

  FinancialsCubit({required IFinancialsRepository financialsRepository})
    : _financialsRepository = financialsRepository,
      super(FinancialsInitial()) {
    _setupCaseChangeListener();
  }

  /// Listen to case changes and reload financials automatically
  void _setupCaseChangeListener() {
    _caseChangeSubscription = CaseChangeNotifier().onCaseChanged.listen((
      event,
    ) {
      // Reload financials when any case is added, updated, or deleted
      if (state is FinancialsLoaded) {
        loadFinancials(force: true);
      }
    });
  }

  @override
  Future<void> close() {
    _caseChangeSubscription?.cancel();
    return super.close();
  }

  Future<void> loadFinancials({bool force = false}) async {
    if (!force && state is FinancialsLoaded) return;

    emit(FinancialsLoading());
    try {
      final isConnected = await ConnectivityService.instance.checkConnection();

      final cases = await _financialsRepository.getAllCases();
      final expenses = await _financialsRepository.getAllExpenses();

      emit(
        FinancialsLoaded(
          cases: cases,
          expenses: expenses,
          isOffline: !isConnected,
        ),
      );
    } catch (e) {
      emit(FinancialsError('خطأ في تحميل البيانات المالية: $e'));
    }
  }

  /// تحميل البيانات المالية بحسب فترة زمنية - Load financials by date range
  Future<void> loadFinancialsByMonth({
    required int year,
    required int month,
  }) async {
    emit(FinancialsLoading());
    try {
      final isConnected = await ConnectivityService.instance.checkConnection();
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0, 23, 59, 59);

      final allCases = await _financialsRepository.getAllCases();
      final filteredCases = allCases.where((c) =>
          c.caseDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
          c.caseDate.isBefore(end.add(const Duration(seconds: 1)))).toList();

      final expenses = await _financialsRepository.getExpensesByRange(start, end);

      emit(
        FinancialsLoaded(
          cases: filteredCases,
          expenses: expenses,
          isOffline: !isConnected,
        ),
      );
    } catch (e) {
      emit(FinancialsError('خطأ في تحميل البيانات المالية: $e'));
    }
  }

  Future<void> addExpense({
    required String label,
    required double amount,
    required String category,
    String? notes,
    required String userId,
  }) async {
    try {
      final expense = ExpenseModel(
        id: DateTime.now().millisecondsSinceEpoch
            .toString(), // Simplified ID for now or use a generator
        category: category,
        label: label,
        amount: amount,
        date: DateTime.now(),
        createdBy: userId,
        notes: notes ?? '',
      );
      await _financialsRepository.createExpense(expense);
      loadFinancials(force: true);
    } catch (e) {
      emit(FinancialsError('خطأ في إضافة المصروف: $e'));
    }
  }

  /// تحديث مصروف - Update expense
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _financialsRepository.updateExpense(expense);
      loadFinancials(force: true);
    } catch (e) {
      emit(FinancialsError('خطأ في تحديث المصروف: $e'));
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      // 1. حذف من SQLite + طابور المزامنة
      await _financialsRepository.deleteExpense(expenseId);

      // 2. تحديث الحالة فوراً بدون إعادة تحميل (لسرعة الاستجابة)
      if (state is FinancialsLoaded) {
        final currentState = state as FinancialsLoaded;
        final updatedExpenses = currentState.expenses
            .where((e) => e.id != expenseId)
            .toList();
        emit(
          FinancialsLoaded(
            cases: currentState.cases,
            expenses: updatedExpenses,
            isOffline: currentState.isOffline,
          ),
        );
      } else {
        // Fallback: إعادة تحميل كامل
        await loadFinancials(force: true);
      }
    } catch (e) {
      emit(FinancialsError('خطأ في حذف المصروف: $e'));
    }
  }
}
