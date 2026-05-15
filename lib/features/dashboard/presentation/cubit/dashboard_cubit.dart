import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notifications/case_change_notifier.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final IDashboardRepository _dashboardRepository;
  StreamSubscription? _caseChangeSubscription;

  DashboardCubit({required IDashboardRepository dashboardRepository})
    : _dashboardRepository = dashboardRepository,
      super(DashboardInitial()) {
    _setupCaseChangeListener();
  }

  /// Listen to case changes and reload dashboard automatically
  void _setupCaseChangeListener() {
    _caseChangeSubscription = CaseChangeNotifier().onCaseChanged.listen((
      event,
    ) {
      // Reload dashboard when any case is added, updated, or deleted
      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        loadDashboardData(date: currentState.selectedDate, force: true);
      }
    });
  }

  @override
  Future<void> close() {
    _caseChangeSubscription?.cancel();
    return super.close();
  }

  Future<void> loadDashboardData({DateTime? date, bool force = false}) async {
    final targetDate =
        date ??
        (state is DashboardLoaded
            ? (state as DashboardLoaded).selectedDate
            : DateTime.now());

    if (!force &&
        state is DashboardLoaded &&
        (state as DashboardLoaded).selectedDate == targetDate) {
      return;
    }

    emit(DashboardLoading());
    try {
      // Assuming repository methods are updated to accept date
      final stats = await _dashboardRepository.getDashboardStats(
        date: targetDate,
      );
      final chartData = await _dashboardRepository
          .getDashboardChartData(nurseId: null); // All data for admin
      final recentCases = await _dashboardRepository.getRecentCases(5);
      final activeStaff = await _dashboardRepository
          .getActiveStaff(); // Active staff is usually current, but could be filtered

      emit(
        DashboardLoaded(
          stats: stats,
          chartData: chartData,
          recentCases: recentCases,
          activeStaff: activeStaff,
          selectedDate: targetDate,
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> loadNurseDashboardData(
    String nurseId, {
    DateTime? date,
    bool force = false,
  }) async {
    final targetDate =
        date ??
        (state is DashboardLoaded
            ? (state as DashboardLoaded).selectedDate
            : DateTime.now());

    if (!force &&
        state is DashboardLoaded &&
        (state as DashboardLoaded).selectedDate == targetDate) {
      return;
    }

    emit(DashboardLoading());
    try {
      final stats = await _dashboardRepository.getNurseDashboardStats(
        nurseId,
        date: targetDate,
      );

      final chartData = await _dashboardRepository.getDashboardChartData(nurseId: nurseId);

      emit(
        DashboardLoaded(
          stats: stats,
          chartData: chartData,
          recentCases: const [],
          activeStaff: const [],
          selectedDate: targetDate,
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
