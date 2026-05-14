import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../domain/repositories/financials_repository.dart';
import '../models/expense_model.dart';
import '../../../cases/data/models/case_model.dart';

/// تنفيذ مستودع البيانات المالية (الجيل الثاني) - Financials Repository Implementation v2
/// Enterprise-grade financial tracking with offline-first support.
class FinancialsRepositoryImpl implements IFinancialsRepository {
  final _local = SqliteService.instance;
  final _sync = SyncManager.instance;

  @override
  Future<void> createExpense(ExpenseModel expense) async {
    // Note: expenses table might need to be added to SqliteService if not already there
    // For now we use generic insert if available or rely on SyncManager for remote
    await _local.insert('expenses', expense.toSqliteMap());
    await _sync.enqueue(
      tableName: 'expenses',
      operation: 'create',
      docId: expense.id,
      data: expense.toMap(),
    );
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await _local.insert('expenses', expense.toSqliteMap());
    await _sync.enqueue(
      tableName: 'expenses',
      operation: 'update',
      docId: expense.id,
      data: expense.toMap(),
    );
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _local.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
    await _sync.enqueue(
      tableName: 'expenses',
      operation: 'delete',
      docId: expenseId,
      data: {},
    );
  }

  @override
  Future<List<ExpenseModel>> getAllExpenses() async {
    final results = await _local.database.then((db) => db.query('expenses', orderBy: 'date DESC'));
    return results.map((m) => ExpenseModel.fromMap(m, m['id'] as String)).toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByRange(DateTime start, DateTime end) async {
    final db = await _local.database;
    final results = await db.query('expenses', 
      where: 'date >= ? AND date <= ?', 
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC'
    );
    return results.map((m) => ExpenseModel.fromMap(m, m['id'] as String)).toList();
  }

  @override
  Future<List<CaseModel>> getAllCases() async {
    final results = await _local.getAllCases();
    return results.map((m) => CaseModel.fromMap(m, m['id'] as String)).toList();
  }
}
