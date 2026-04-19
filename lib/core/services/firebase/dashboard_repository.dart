import '../../../features/cases/data/models/case_model.dart';
import 'cases_repository.dart';
import 'firebase_base.dart';

/// مستودع لوحة التحكم - Dashboard Repository
/// تجميع الإحصائيات من المستودعات الأخرى
class DashboardRepository extends FirebaseBase {
  final CasesRepository _casesRepository;

  DashboardRepository({CasesRepository? casesRepository})
      : _casesRepository = casesRepository ?? CasesRepository();

  /// إحصائيات سريعة - Quick stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final results = await Future.wait([
      firestore.collection('cases').count().get(),
      firestore.collection('cases')
          .where('caseDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('caseDate', isLessThan: endOfDay.toIso8601String())
          .count()
          .get(),
      firestore.collection('cases').where('status', isEqualTo: 'pending').count().get(),
      firestore.collection('cases').where('status', isEqualTo: 'in_progress').count().get(),
      firestore.collection('cases').where('status', isEqualTo: 'completed').count().get(),
      firestore.collection('users')
          .where('role', isEqualTo: 'nurse')
          .where('isActive', isEqualTo: true)
          .count()
          .get(),
    ]);

    final todayCases = await _casesRepository.getTodayCases();
    final todayCompletedCases = todayCases.where((c) => c.status.name == 'completed').toList();

    double todayRevenue = 0;
    for (final c in todayCompletedCases) {
      todayRevenue += c.totalPrice - c.discount;
    }

    return {
      'totalPatients': results[0].count ?? 0,
      'todayCases': todayCases.length,
      'pendingCases': todayCases.where((c) => c.status.name == 'pending').length,
      'inProgressCases': todayCases.where((c) => c.status.name == 'in_progress').length,
      'completedCases': todayCompletedCases.length,
      'availableNurses': results[5].count ?? 0,
      'todayRevenue': todayRevenue,
    };
  }

  /// بيانات الرسم البياني للأسبوع - Weekly chart data
  Future<Map<String, List<double>>> getDashboardChartData() async {
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    final snapshot = await firestore.collection('cases')
        .where('caseDate', isGreaterThanOrEqualTo: sevenDaysAgo.toIso8601String())
        .get();

    final allCases = snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data(), doc.id))
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

      double dayRevenue = 0;
      for (final c in dayCases) {
        if (c.status.name == 'completed') {
          dayRevenue += (c.totalPrice - c.discount);
        }
      }
      revenues[i] = dayRevenue;
    }

    return {
      'counts': counts,
      'revenues': revenues,
    };
  }
}
