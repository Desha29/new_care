import '../../../cases/data/models/case_model.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../cases/domain/repositories/cases_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/services/local/sqlite_service.dart';


/// تنفيذ مستودع لوحة التحكم (الجيل الثاني) - Dashboard Repository Implementation v2
/// Optimized for speed using local data and reliable remote fallbacks.
class DashboardRepositoryImpl implements IDashboardRepository {
  final ICasesRepository _casesRepository;
  final _local = SqliteService.instance;

  DashboardRepositoryImpl({required ICasesRepository casesRepository})
    : _casesRepository = casesRepository;

  @override
  Future<Map<String, dynamic>> getDashboardStats({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final db = await _local.database;
    
    // Server-side aggregation was slow/delayed; compute from local SQLite for real-time speed.
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day).toIso8601String();
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59).toIso8601String();

    final todayCasesResult = await db.query(
      'cases',
      where: 'caseDate >= ? AND caseDate <= ?',
      whereArgs: [start, end],
    );

    double totalRevenue = 0.0;
    for (var c in todayCasesResult) {
      final price = (c['totalPrice'] as num?)?.toDouble() ?? 0.0;
      final discount = (c['discount'] as num?)?.toDouble() ?? 0.0;
      totalRevenue += (price - discount);
    }
    
    final totalPatients = await _local.getPatientsCount();

    // Get active nurses from local users cache
    final nurses = await db.query(
      'users',
      where: 'role = ? AND isActive = 1',
      whereArgs: ['nurse'],
    );

    // حساب إجمالي مصروفات اليوم - Calculate today's total expenses
    final todayExpensesResult = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start, end],
    );
    double totalExpenses = 0.0;
    for (var e in todayExpensesResult) {
      totalExpenses += (e['amount'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'totalPatients': totalPatients,
      'todayCases': todayCasesResult.length,
      'availableNurses': nurses.length,
      'todayRevenue': totalRevenue,
      'todayExpenses': totalExpenses,
    };
  }

  @override
  Future<Map<String, dynamic>> getNurseDashboardStats(String nurseId, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final startOfMonth = DateTime(targetDate.year, targetDate.month, 1);

    // Read from local for speed
    final allNurseCases = await _casesRepository.getNurseCases(nurseId);

    final monthlyCases = allNurseCases
        .where(
          (c) =>
              c.caseDate.isAfter(startOfMonth) ||
              c.caseDate.isAtSameMomentAs(startOfMonth),
        )
        .toList();
    final todayCases = allNurseCases
        .where(
          (c) =>
              c.caseDate.year == targetDate.year &&
              c.caseDate.month == targetDate.month &&
              c.caseDate.day == targetDate.day,
        )
        .toList();

    // Attendance status from local
    final db = await _local.database;
    final dateStr =
        '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    final attendanceResults = await db.query(
      'attendance',
      where: 'userId = ? AND date = ?',
      whereArgs: [nurseId, dateStr],
      orderBy: 'checkInTime DESC',
      limit: 1,
    );

    final attendance = attendanceResults.isNotEmpty
        ? AttendanceModel.fromMap(
            attendanceResults.first,
            attendanceResults.first['id'] as String,
          )
        : null;

    // Get base salary for nurse
    final nurseResults = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [nurseId],
      limit: 1,
    );
    final baseSalary = nurseResults.isNotEmpty 
        ? (nurseResults.first['salary'] as num? ?? 0.0).toDouble() 
        : 0.0;

    return {
      'monthlyCases': monthlyCases.length,
      'totalIncome': monthlyCases.fold(
        0.0,
        (total, c) => total + (c.totalPrice - c.discount),
      ),
      'estimatedSalary': baseSalary, // Base salary from user profile
      'todayCases': todayCases.length,
      'todayCasesList': todayCases,
      'attendance': attendance,
    };
  }

  @override
  Future<Map<String, List<double>>> getDashboardChartData({String? nurseId}) async {
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    // For charts, we use local data if available
    final results = await _local.getAllCases();
    var allCases = results
        .map((m) => CaseModel.fromMap(m, m['id'] as String))
        .toList();

    if (nurseId != null) {
      allCases = allCases.where((c) => c.nurseId == nurseId).toList();
    }

    List<double> counts = List.filled(7, 0.0);
    List<double> revenues = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
      final targetDate = sevenDaysAgo.add(Duration(days: i));
      final dayCases = allCases.where((c) {
        return c.caseDate.year == targetDate.year &&
            c.caseDate.month == targetDate.month &&
            c.caseDate.day == targetDate.day;
      }).toList();

      counts[i] = dayCases.length.toDouble();
      revenues[i] = dayCases.fold(
        0.0,
        (total, c) => total + (c.totalPrice - c.discount),
      );
    }

    return {'counts': counts, 'revenues': revenues};
  }

  @override
  Future<List<CaseModel>> getRecentCases(int limit) async {
    final results = await _local.database.then(
      (db) => db.query('cases', orderBy: 'caseDate DESC', limit: limit),
    );
    return results.map((m) => CaseModel.fromMap(m, m['id'] as String)).toList();
  }

  @override
  Future<List<AttendanceModel>> getActiveStaff() async {
    final db = await _local.database;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Get all attendance for today to show who is/was working
    final results = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [todayStr],
      orderBy: 'checkInTime DESC',
    );

    return results
        .map((m) => AttendanceModel.fromMap(m, m['id'] as String))
        .toList();
  }
}
