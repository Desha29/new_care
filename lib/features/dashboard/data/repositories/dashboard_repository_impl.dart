import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase/firebase_base.dart';
import '../../../cases/data/models/case_model.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../cases/domain/repositories/cases_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// تنفيذ مستودع لوحة التحكم - Dashboard Repository Implementation
class DashboardRepositoryImpl extends FirebaseBase implements IDashboardRepository {
  final ICasesRepository _casesRepository;

  DashboardRepositoryImpl({required ICasesRepository casesRepository})
    : _casesRepository = casesRepository;

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final results = await Future.wait([
      firestore.collection('cases').count().get(),
      firestore
          .collection('cases')
          .where('caseDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('caseDate', isLessThan: endOfDay.toIso8601String())
          .count()
          .get(),
      firestore
          .collection('users')
          .where('role', isEqualTo: 'nurse')
          .where('isActive', isEqualTo: true)
          .count()
          .get(),
    ]);

    final todayCases = await _casesRepository.getTodayCases();
    double todayRevenue = 0;
    for (final c in todayCases) {
      todayRevenue += (c.totalPrice - c.discount);
    }

    return {
      'totalPatients': results[0].count ?? 0,
      'todayCases': todayCases.length,
      'availableNurses': results[2].count ?? 0,
      'todayRevenue': todayRevenue,
    };
  }

  @override
  Future<Map<String, dynamic>> getNurseDashboardStats(String nurseId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final results = await Future.wait([
      firestore
          .collection('cases')
          .where('nurseId', isEqualTo: nurseId)
          .where('caseDate', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .get(),
      firestore
          .collection('cases')
          .where('nurseId', isEqualTo: nurseId)
          .where('caseDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .get(),
      firestore
          .collection('attendance')
          .where('userId', isEqualTo: nurseId)
          .where('checkInTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .get(),
    ]);

    final monthlyCases = results[0].docs
        .map((doc) => CaseModel.fromMap(doc.data()!, doc.id))
        .toList();

    final todayCases = results[1].docs
        .map((doc) => CaseModel.fromMap(doc.data()!, doc.id))
        .toList();

    final attendanceDocs = results[2].docs;
    final attendance = attendanceDocs.isNotEmpty 
        ? AttendanceModel.fromMap(attendanceDocs.first.data()!, attendanceDocs.first.id)
        : null;

    return {
      'monthlyCases': monthlyCases.length,
      'totalIncome': monthlyCases.fold(0.0, (total, c) => total + (c.totalPrice - c.discount)),
      'todayCases': todayCases,
      'todayCasesCount': todayCases.length,
      'attendance': attendance,
    };
  }

  @override
  Future<Map<String, List<double>>> getDashboardChartData() async {
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    final snapshot = await firestore
        .collection('cases')
        .where('caseDate', isGreaterThanOrEqualTo: sevenDaysAgo.toIso8601String())
        .get();

    final allCases = snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data()!, doc.id))
        .toList();

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
      revenues[i] = dayCases.fold(0.0, (total, c) => total + (c.totalPrice - c.discount));
    }

    return {'counts': counts, 'revenues': revenues};
  }

  @override
  Future<List<CaseModel>> getRecentCases(int limit) async {
    final snapshot = await firestore
        .collection('cases')
        .orderBy('caseDate', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data()!, doc.id))
        .toList();
  }

  @override
  Future<List<AttendanceModel>> getActiveStaff() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await firestore
        .collection('attendance')
        .where('checkInTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('status', isEqualTo: 'checked_in')
        .get();

    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data()!, doc.id))
        .toList();
  }
}
