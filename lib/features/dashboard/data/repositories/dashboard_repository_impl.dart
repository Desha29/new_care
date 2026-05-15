import '../../../cases/data/models/case_model.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../cases/domain/repositories/cases_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/firebase/firebase_service.dart';

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
    
    // Server-side aggregation (Optimized for 5000+ records)
    final aggregates = await FirebaseService.instance.getDailyAggregates(date: targetDate);
    
    final totalPatients = await _local.getPatientsCount();

    // Get active nurses from local users cache
    final nurses = await _local.database.then(
      (db) => db.query(
        'users',
        where: 'role = ? AND isActive = 1',
        whereArgs: ['nurse'],
      ),
    );

    return {
      'totalPatients': totalPatients,
      'todayCases': aggregates['totalCases'],
      'availableNurses': nurses.length,
      'todayRevenue': aggregates['totalRevenue'],
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
    final todayStr =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    final results = await db.query(
      'attendance',
      where: 'date = ? AND status = ?',
      whereArgs: [todayStr, 'checked_in'],
    );

    return results
        .map((m) => AttendanceModel.fromMap(m, m['id'] as String))
        .toList();
  }
}
