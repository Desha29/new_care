import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/financials/data/models/expense_model.dart';
import '../../constants/app_constants.dart';
import 'firebase_base.dart';

/// مستودع المصاريف - Expenses Repository
class ExpensesRepository extends FirebaseBase {
  CollectionReference get _expensesRef =>
      firestore.collection(AppConstants.expensesCollection);

  /// إنشاء مصروف - Create expense
  Future<void> createExpense(ExpenseModel expense) async {
    await _expensesRef.doc(expense.id).set(expense.toMap());
  }

  /// تحديث مصروف - Update expense
  Future<void> updateExpense(ExpenseModel expense) async {
    await _expensesRef.doc(expense.id).update(expense.toMap());
  }

  /// حذف مصروف - Delete expense
  Future<void> deleteExpense(String expenseId) async {
    await _expensesRef.doc(expenseId).delete();
  }

  /// جلب جميع المصاريف - Get all expenses
  Future<List<ExpenseModel>> getAllExpenses() async {
    final snapshot = await _expensesRef.orderBy('date', descending: true).get();
    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب مصاريف بحسب التاريخ - Get expenses by date range
  Future<List<ExpenseModel>> getExpensesByRange(DateTime start, DateTime end) async {
    final snapshot = await _expensesRef
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .get();
    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
