import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase/firebase_base.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/financials_repository.dart';
import '../models/expense_model.dart';
import '../../../cases/data/models/case_model.dart';

/// تنفيذ مستودع البيانات المالية - Financials Repository Implementation
class FinancialsRepositoryImpl extends FirebaseBase implements IFinancialsRepository {
  CollectionReference get _expensesRef =>
      firestore.collection(AppConstants.expensesCollection);

  CollectionReference get _casesRef =>
      firestore.collection(AppConstants.casesCollection);

  @override
  Future<void> createExpense(ExpenseModel expense) async {
    await _expensesRef.doc(expense.id).set(expense.toMap());
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await _expensesRef.doc(expense.id).update(expense.toMap());
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _expensesRef.doc(expenseId).delete();
  }

  @override
  Future<List<ExpenseModel>> getAllExpenses() async {
    final snapshot = await _expensesRef.orderBy('date', descending: true).get();
    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByRange(DateTime start, DateTime end) async {
    final snapshot = await _expensesRef
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .get();
    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<List<CaseModel>> getAllCases() async {
    final snapshot = await _casesRef.orderBy('caseDate', descending: true).get();
    return snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
