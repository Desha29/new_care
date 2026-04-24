import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../cases/data/models/case_model.dart';
import '../../../../core/enums/user_role.dart';

/// تنفيذ مستودع الرواتب (الجيل الثاني) - Payroll Repository Implementation v2
/// Optimized for performance using local data.
class PayrollRepositoryImpl implements IPayrollRepository {
  final _local = SqliteService.instance;
  final _remote = FirebaseService.instance;

  @override
  Future<List<UserModel>> getActiveStaff() async {
    final results = await _local.database.then((db) => db.query('users', where: 'isActive = 1'));
    if (results.isEmpty) {
      // Fallback to remote if local is empty
      final remote = await _remote.getAllUsers();
      for (var u in remote) {
        await _local.saveUser(u.toSqliteMap());
      }
      return remote.where((u) => u.isActive).toList();
    }
    
    return results
        .map((m) => UserModel.fromMap(m, m['id'] as String))
        .where((u) =>
            u.role == UserRole.nurse ||
            u.role == UserRole.admin ||
            u.role == UserRole.superAdmin)
        .toList();
  }

  @override
  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(int year, int month) async {
    // For payroll, we prefer remote data to ensure we have the full month even if devices switched
    return await _remote.getMonthlyAttendanceRecords(year, month);
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
}
