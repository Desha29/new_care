import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final IDashboardRepository _dashboardRepository;

  DashboardCubit({
    required IDashboardRepository dashboardRepository,
  }) : _dashboardRepository = dashboardRepository,
       super(DashboardInitial());

  Future<void> loadDashboardData() async {
    emit(DashboardLoading());
    try {
      final stats = await _dashboardRepository.getDashboardStats();
      final chartData = await _dashboardRepository.getDashboardChartData();
      final recentCases = await _dashboardRepository.getRecentCases(5);
      final activeStaff = await _dashboardRepository.getActiveStaff();

      emit(DashboardLoaded(
        stats: stats,
        chartData: chartData,
        recentCases: recentCases,
        activeStaff: activeStaff,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> loadNurseDashboardData(String nurseId) async {
    emit(DashboardLoading());
    try {
      final stats = await _dashboardRepository.getNurseDashboardStats(nurseId);
      // You can add more nurse specific data here if needed
      
      emit(DashboardLoaded(
        stats: stats,
        chartData: const {}, // Or nurse specific chart data
        recentCases: const [],
        activeStaff: const [],
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
