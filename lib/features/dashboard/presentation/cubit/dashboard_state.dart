import '../../../cases/data/models/case_model.dart';
import '../../../attendance/data/models/attendance_model.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Map<String, dynamic> stats;
  final Map<String, List<double>> chartData;
  final List<CaseModel> recentCases;
  final List<AttendanceModel> activeStaff;
  final DateTime selectedDate;

  DashboardLoaded({
    required this.stats,
    required this.chartData,
    required this.recentCases,
    required this.activeStaff,
    required this.selectedDate,
  });
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
