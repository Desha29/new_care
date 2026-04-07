import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../cases/data/models/case_model.dart';
import '../../data/models/expense_model.dart';

part 'financials_state.dart';

class FinancialsCubit extends Cubit<FinancialsState> {
  final FirebaseService _firebaseService;

  FinancialsCubit()
      : _firebaseService = FirebaseService.instance,
        super(FinancialsInitial());

  Future<void> loadFinancials() async {
    emit(FinancialsLoading());
    try {
      final isConnected = await ConnectivityService.instance.checkConnection();
      
      final cases = await _firebaseService.getAllCases();
      final expenses = await _firebaseService.getAllExpenses();
      
      emit(FinancialsLoaded(
        cases: cases,
        expenses: expenses,
        isOffline: !isConnected,
      ));
    } catch (e) {
      emit(FinancialsError('خطأ في تحميل البيانات المالية: $e'));
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _firebaseService.createExpense(expense);
      loadFinancials();
    } catch (e) {
      emit(FinancialsError('خطأ في إضافة المصروف: $e'));
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firebaseService.deleteExpense(expenseId);
      loadFinancials();
    } catch (e) {
      emit(FinancialsError('خطأ في حذف المصروف: $e'));
    }
  }
}
