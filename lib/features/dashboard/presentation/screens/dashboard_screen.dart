import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../cases/data/models/case_model.dart';
import 'package:intl/intl.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/logic/cubit/auth_cubit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _isOffline = false;

  Map<String, dynamic> _stats = {
    'todayCases': 0,
    'totalPatients': 0,
    'todayRevenue': 0.0,
    'availableNurses': 0,
    'pendingCases': 0,
    'inProgressCases': 0,
    'completedCases': 0,
  };

  List<CaseModel> _recentCases = [];
  List<double> _weeklyCounts = List.filled(7, 0.0);
  List<double> _weeklyRevenues = List.filled(7, 0.0);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final isConnected = await ConnectivityService.instance.checkConnection();
      if (!isConnected) {
        if (mounted) {
          setState(() {
            _isOffline = true;
            _isLoading = false;
          });
        }
        return;
      }

      final stats = await FirebaseService.instance.getDashboardStats();
      final chartData = await FirebaseService.instance.getDashboardChartData();
      final cases = await FirebaseService.instance.getTodayCases();

      cases.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // الأحدث أولاً
      final recent = cases.take(5).toList();

      if (mounted) {
        setState(() {
          _stats = stats;
          _recentCases = recent;
          _weeklyCounts = chartData['counts']!;
          _weeklyRevenues = chartData['revenues']!;
          _isOffline = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final isSmall = !ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isOffline)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              AppStrings.offlineMode,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadDashboardData,
                            child: const Text(
                              'إعادة المحاولة',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // === الرأس - Header ===
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // === بطاقات الإحصائيات - Stats Cards ===
                  _buildStatsCards(),
                  const SizedBox(height: 24),

                  // === الرسوم البيانية - Charts ===
                  if (isSmall) ...[
                    _buildCasesChart(),
                    const SizedBox(height: 20),
                    _buildStatusPieChart(),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildCasesChart()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _buildStatusPieChart()),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // === الإيرادات والحالات الأخيرة ===
                  if (isSmall) ...[
                    _buildRevenueChart(),
                    const SizedBox(height: 20),
                    _buildRecentCases(),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildRevenueChart()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _buildRecentCases()),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'صباح الخير'
        : now.hour < 18
        ? 'مساء الخير'
        : 'مساء الخير';
    final user = context.read<AuthCubit>().currentUser;
    final titleSize = ResponsiveHelper.getTitleFontSize(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting ${user?.name ?? ""} 👋',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isMobile ? 12 : 14,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              AppStrings.dashboard,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        // تاريخ اليوم
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${now.day}/${now.month}/${now.year}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _loadDashboardData,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بطاقات الإحصائيات - Stats Cards Grid
  Widget _buildStatsCards() {
    final columns = ResponsiveHelper.getStatCardColumns(context);
    final aspectRatio = ResponsiveHelper.getAspectRatio(context);

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio,
      children: [
        StatCard(
          title: AppStrings.todayCases,
          value: '${_stats['todayCases']}',
          icon: Icons.medical_services_rounded,
          color: AppColors.info,
          subtitle: 'حالة اليوم',
        ),
        StatCard(
          title: AppStrings.totalPatients,
          value: '${_stats['totalPatients']}',
          icon: Icons.people_rounded,
          color: AppColors.secondary,
          subtitle: 'مريض مسجل',
        ),
        StatCard(
          title: AppStrings.totalRevenue,
          value: (_stats['todayRevenue'] as double).toStringAsFixed(0),
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.success,
          subtitle: '${AppStrings.currency} إيرادات اليوم',
        ),
        StatCard(
          title: AppStrings.availableNurses,
          value: '${_stats['availableNurses']}',
          icon: Icons.person_rounded,
          color: const Color(0xFF8B5CF6),
          subtitle: 'ممرض نشط',
        ),
      ],
    );
  }

  /// رسم بياني للحالات الأسبوعية - Weekly Cases Bar Chart
  Widget _buildCasesChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.casesOverview,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'حالات آخر 7 أيام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_weeklyCounts.reduce((a, b) => a > b ? a : b) + 5),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primaryDark,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final now = DateTime.now();
                      final date = now.subtract(Duration(days: 6 - group.x));
                      final dayName = DateFormat('EEEE', 'ar').format(date);
                      return BarTooltipItem(
                        '$dayName\n${rod.toY.toInt()} حالة',
                        const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final now = DateTime.now();
                        final date = now.subtract(
                          Duration(days: 6 - value.toInt()),
                        );
                        final dayInit = DateFormat(
                          'E',
                          'ar',
                        ).format(date).substring(0, 1);
                        return Text(
                          dayInit,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.borderLight, strokeWidth: 1);
                  },
                ),
                barGroups: List.generate(
                  7,
                  (i) => _makeBarGroup(i, _weeklyCounts[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  /// رسم بياني دائري لحالات الأعمال - Status Pie Chart
  Widget _buildStatusPieChart() {
    final pending = (_stats['pendingCases'] as int).toDouble();
    final inProgress = (_stats['inProgressCases'] as int).toDouble();
    final completed = (_stats['completedCases'] as int).toDouble();

    final total = pending + inProgress + completed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حالات اليوم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: total == 0
                ? const Center(
                    child: Text(
                      "لا توجد بيانات اليوم",
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        if (pending > 0)
                          PieChartSectionData(
                            color: AppColors.statusPending,
                            value: pending,
                            title: '${pending.toInt()}',
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            radius: 45,
                          ),
                        if (inProgress > 0)
                          PieChartSectionData(
                            color: AppColors.statusInProgress,
                            value: inProgress,
                            title: '${inProgress.toInt()}',
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            radius: 45,
                          ),
                        if (completed > 0)
                          PieChartSectionData(
                            color: AppColors.statusCompleted,
                            value: completed,
                            title: '${completed.toInt()}',
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            radius: 45,
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          // الأسطورة - Legend
          _buildLegendItem(
            AppColors.statusPending,
            AppStrings.pending,
            pending.toInt(),
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            AppColors.statusInProgress,
            AppStrings.inProgress,
            inProgress.toInt(),
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            AppColors.statusCompleted,
            AppStrings.completed,
            completed.toInt(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int count) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// رسم بياني للإيرادات - Revenue Line Chart
  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.revenueOverview,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'الإيرادات خلال آخر 7 أيام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.borderLight, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final now = DateTime.now();
                        final date = now.subtract(
                          Duration(days: 6 - value.toInt()),
                        );
                        final dayInit = DateFormat(
                          'E',
                          'ar',
                        ).format(date).substring(0, 1);
                        return Text(
                          dayInit,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: (_weeklyRevenues.reduce((a, b) => a > b ? a : b) + 1000),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      7,
                      (i) => FlSpot(i.toDouble(), _weeklyRevenues[i]),
                    ),
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.success,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.success.withValues(alpha: 0.2),
                          AppColors.success.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// أحدث الحالات - Recent Cases List
  Widget _buildRecentCases() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.recentCases,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentCases.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "لا يوجد حالات اليوم",
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            )
          else
            ..._recentCases.map((c) => _buildRecentCaseItem(c)),
        ],
      ),
    );
  }

  Widget _buildRecentCaseItem(CaseModel caseData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caseData.patientName.isNotEmpty
                      ? caseData.patientName
                      : 'مريض غير معروف',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${caseData.caseType.label} • ${DateFormat('hh:mm a').format(caseData.createdAt)}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: caseData.status.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              caseData.status.label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: caseData.status.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
