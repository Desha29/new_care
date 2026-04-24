import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/network/connectivity_service.dart';
import '../../domain/repositories/financials_repository.dart';
import '../../../cases/data/models/case_model.dart';
import '../../data/models/expense_model.dart';

part 'financials_state.dart';

class FinancialsCubit extends Cubit<FinancialsState> {
  final IFinancialsRepository _financialsRepository;

  FinancialsCubit({required IFinancialsRepository financialsRepository})
      : _financialsRepository = financialsRepository,
        super(FinancialsInitial());

  Future<void> loadFinancials() async {
    emit(FinancialsLoading());
    try {
      final isConnected = await ConnectivityService.instance.checkConnection();
      
      final cases = await _financialsRepository.getAllCases();
      final expenses = await _financialsRepository.getAllExpenses();
      
      emit(FinancialsLoaded(
        cases: cases,
        expenses: expenses,
        isOffline: !isConnected,
      ));
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
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Simplified ID for now or use a generator
        category: category,
        label: label,
        amount: amount,
        date: DateTime.now(),
        createdBy: userId,
        notes: notes ?? '',
      );
      await _financialsRepository.createExpense(expense);
      loadFinancials();
    } catch (e) {
      emit(FinancialsError('خطأ في إضافة المصروف: $e'));
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _financialsRepository.deleteExpense(expenseId);
      loadFinancials();
    } catch (e) {
      emit(FinancialsError('خطأ في حذف المصروف: $e'));
    }
  }
}

