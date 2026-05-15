import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_care/core/constants/app_colors.dart';
import 'package:new_care/core/utils/responsive_helper.dart';
import 'package:new_care/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:new_care/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:new_care/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:new_care/features/dashboard/presentation/screens/nurse_dashboard_screen.dart';
import 'package:new_care/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:new_care/features/dashboard/presentation/widgets/stats_cards_grid.dart';
import 'package:new_care/features/dashboard/presentation/widgets/dashboard_weekly_chart.dart';
import 'package:new_care/features/dashboard/presentation/widgets/dashboard_kpi_metrics.dart';
import 'package:new_care/features/dashboard/presentation/widgets/dashboard_revenue_chart.dart';
import 'package:new_care/features/dashboard/presentation/widgets/dashboard_recent_cases.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAllCases;
  const DashboardScreen({super.key, this.onViewAllCases});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;
    final isAdmin = user?.role.isAdmin ?? false;

    if (!isAdmin) {
      return NurseDashboardScreen(onViewAll: widget.onViewAllCases);
    }

    final padding = ResponsiveHelper.getScreenPadding(context);
    final isSmall = !ResponsiveHelper.isDesktop(context);

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DashboardError) {
          return Scaffold(
            body: Center(child: Text('Error: ${state.message}')),
          );
        }

        if (state is DashboardLoaded) {
          final stats = state.stats;
          final recentCases = state.recentCases;
          final weeklyCounts = state.chartData['counts'] ?? List.filled(7, 0.0);
          final weeklyRevenues = state.chartData['revenues'] ?? List.filled(7, 0.0);

          return Scaffold(
            backgroundColor: AppColors.background,
            body: RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().loadDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DashboardHeader(),
                          const SizedBox(height: 24),
                          StatsCardsGrid(stats: stats),
                          const SizedBox(height: 24),

                          if (isSmall) ...[
                            DashboardWeeklyChart(weeklyCounts: weeklyCounts),
                            const SizedBox(height: 20),
                            DashboardKpiMetrics(stats: stats),
                            const SizedBox(height: 20),
                            DashboardRevenueChart(weeklyRevenues: weeklyRevenues),
                            const SizedBox(height: 20),
                            DashboardRecentCases(recentCases: recentCases),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      DashboardWeeklyChart(weeklyCounts: weeklyCounts),
                                      const SizedBox(height: 20),
                                      DashboardRevenueChart(weeklyRevenues: weeklyRevenues),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      DashboardKpiMetrics(stats: stats),
                                      const SizedBox(height: 20),
                                      DashboardRecentCases(recentCases: recentCases),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
