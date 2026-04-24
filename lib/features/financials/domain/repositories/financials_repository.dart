import '../../data/models/expense_model.dart';
import '../../../cases/data/models/case_model.dart';

/// واجهة مستودع البيانات المالية - Financials Repository Interface
abstract class IFinancialsRepository {
  /// جلب جميع المصاريف - Get all expenses
  Future<List<ExpenseModel>> getAllExpenses();

  /// جلب مصاريف بحسب التاريخ - Get expenses by date range
  Future<List<ExpenseModel>> getExpensesByRange(DateTime start, DateTime end);

  /// جلب جميع الحالات (للإيرادات) - Get all cases (for revenue)
  Future<List<CaseModel>> getAllCases();

  /// إنشاء مصروف - Create expense
  Future<void> createExpense(ExpenseModel expense);

  /// تحديث مصروف - Update expense
  Future<void> updateExpense(ExpenseModel expense);

  /// حذف مصروف - Delete expense
  Future<void> deleteExpense(String expenseId);
}
