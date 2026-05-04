import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../../data/models/payroll_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../cases/data/models/case_model.dart';
import '../../../../core/enums/user_role.dart';

/// تنفيذ مستودع الرواتب (الجيل الثاني) - Payroll Repository Implementation v2
/// Local-first payroll management with sync queue support.
class PayrollRepositoryImpl implements IPayrollRepository {
  final _local = SqliteService.instance;
  final _sync = SyncManager.instance;

  @override
  Future<List<UserModel>> getActiveStaff() async {
    final results = await _local.database.then((db) => db.query('users', where: 'isActive = 1'));
    if (results.isEmpty) return [];

    // فقط الممرضين لهم رواتب - Only nurses have payroll
    return results
        .map((m) => UserModel.fromMap(m, m['id'] as String))
        .where((u) => u.role == UserRole.nurse)
        .toList();
  }

  @override
  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(int year, int month) async {
    // قراءة الحضور من SQLite أولاً (local-first)
    final db = await _local.database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final endDate = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    final results = await db.query(
      'attendance',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
    );

    return results
        .map((m) => AttendanceModel.fromMap(m, m['id'] as String))
        .toList();
  }

  @override
  Future<List<CaseModel>> getMonthlyCases(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final results = await _local.database.then((db) => db.query(
      'cases',
      where: 'caseDate >= ? AND caseDate <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    ));

    if (results.isNotEmpty) {
      return results.map((m) => CaseModel.fromMap(m, m['id'] as String)).toList();
    }
    return [];
  }

  @override
  Future<void> savePayroll(PayrollModel payroll, {bool isNew = true}) async {
    // 1. حفظ محلياً في SQLite
    await _local.insert('payroll', payroll.toSqliteMap());
    // 2. إضافة لطابور المزامنة
    await _sync.enqueue(
      tableName: 'payroll',
      operation: isNew ? 'create' : 'update',
      docId: payroll.id,
      data: payroll.toMap(),
    );
  }

  @override
  Future<void> savePayrollBatch(List<PayrollModel> payrolls) async {
    // حفظ مجموعة الرواتب محلياً ثم إضافتها للمزامنة
    final maps = payrolls.map((p) => p.toSqliteMap()).toList();
    await _local.insertBatch('payroll', maps);
    // إضافة كل سجل لطابور المزامنة
    for (final payroll in payrolls) {
      await _sync.enqueue(
        tableName: 'payroll',
        operation: 'create',
        docId: payroll.id,
        data: payroll.toMap(),
      );
    }
  }

  @override
  Future<List<PayrollModel>> getPayrolls(int year, int month) async {
    final db = await _local.database;
    final results = await db.query(
      'payroll',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'userName ASC',
    );

    return results
        .map((m) => PayrollModel.fromMap(m, m['id'] as String))
        .toList();
  }

  @override
  Future<void> updatePayrollStatus(String payrollId, String status) async {
    final db = await _local.database;
    // 1. قراءة السجل المحلي
    final existing = await _local.getById('payroll', payrollId);
    if (existing == null) return;

    // 2. تحديث الحالة محلياً
    final now = DateTime.now().toIso8601String();
    await db.update(
      'payroll',
      {'status': status, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [payrollId],
    );

    // 3. إضافة للمزامنة
    final updatedMap = Map<String, dynamic>.from(existing);
    updatedMap['status'] = status;
    updatedMap['updatedAt'] = now;
    await _sync.enqueue(
      tableName: 'payroll',
      operation: 'update',
      docId: payrollId,
      data: updatedMap,
    );
  }

  @override
  Future<void> deletePayroll(String payrollId) async {
    await _local.delete('payroll', where: 'id = ?', whereArgs: [payrollId]);
    await _sync.enqueue(
      tableName: 'payroll',
      operation: 'delete',
      docId: payrollId,
      data: {},
    );
  }
}
