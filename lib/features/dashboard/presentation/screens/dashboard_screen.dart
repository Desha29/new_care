import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/stat_card.dart';

/// شاشة لوحة التحكم - Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // بيانات تجريبية - Sample data (will be replaced with Firebase data)
  final Map<String, dynamic> _stats = {
    'todayCases': 12,
    'totalPatients': 248,
    'todayRevenue': 4580.0,
    'availableNurses': 8,
    'pendingCases': 5,
    'inProgressCases': 3,
    'completedCases': 4,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === الرأس - Header ===
            _buildHeader(),
            const SizedBox(height: 24),

            // === بطاقات الإحصائيات - Stats Cards ===
            _buildStatsCards(),
            const SizedBox(height: 24),

            // === الرسوم البيانية - Charts ===
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رسم بياني للحالات - Cases Chart
                Expanded(flex: 3, child: _buildCasesChart()),
                const SizedBox(width: 20),
                // رسم بياني دائري - Pie Chart
                Expanded(flex: 2, child: _buildStatusPieChart()),
              ],
            ),
            const SizedBox(height: 24),

            // === الإيرادات والحالات الأخيرة - Revenue & Recent Cases ===
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

  /// الرأس - Header
  Widget _buildHeader() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'صباح الخير'
        : now.hour < 18
            ? 'مساء الخير'
            : 'مساء الخير';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting 👋',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const Text(
              AppStrings.dashboard,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 26,
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
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
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
            ],
          ),
        ),
      ],
    );
  }

  /// بطاقات الإحصائيات - Stats Cards Grid
  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
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
          subtitle: 'ممرض متاح',
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
            'نظرة على حالات الأسبوع الحالي',
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
                maxY: 15,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primaryDark,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
                      return BarTooltipItem(
                        '${days[group.x]}\n${rod.toY.toInt()} حالة',
                        const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 12),
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
                        final days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
                        return Text(
                          days[value.toInt()],
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint),
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
                          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                barGroups: [
                  _makeBarGroup(0, 8),
                  _makeBarGroup(1, 10),
                  _makeBarGroup(2, 6),
                  _makeBarGroup(3, 12),
                  _makeBarGroup(4, 9),
                  _makeBarGroup(5, 11),
                  _makeBarGroup(6, 4),
                ],
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
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: AppColors.statusPending,
                    value: pending,
                    title: '${pending.toInt()}',
                    titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    radius: 45,
                  ),
                  PieChartSectionData(
                    color: AppColors.statusInProgress,
                    value: inProgress,
                    title: '${inProgress.toInt()}',
                    titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    radius: 45,
                  ),
                  PieChartSectionData(
                    color: AppColors.statusCompleted,
                    value: completed,
                    title: '${completed.toInt()}',
                    titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    radius: 45,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // الأسطورة - Legend
          _buildLegendItem(AppColors.statusPending, AppStrings.pending, pending.toInt()),
          const SizedBox(height: 8),
          _buildLegendItem(AppColors.statusInProgress, AppStrings.inProgress, inProgress.toInt()),
          const SizedBox(height: 8),
          _buildLegendItem(AppColors.statusCompleted, AppStrings.completed, completed.toInt()),
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
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          '$count',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
            'الإيرادات خلال الأسبوع الماضي',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textHint),
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
                        final days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
                        if (value.toInt() < days.length) {
                          return Text(days[value.toInt()],
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 10, color: AppColors.textHint));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 6000,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2400),
                      FlSpot(1, 3200),
                      FlSpot(2, 1800),
                      FlSpot(3, 4100),
                      FlSpot(4, 3600),
                      FlSpot(5, 4580),
                      FlSpot(6, 2000),
                    ],
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
    final recentCases = [
      {'name': 'أحمد محمد', 'status': 'completed', 'type': 'داخل المركز', 'time': '10:30'},
      {'name': 'فاطمة علي', 'status': 'in_progress', 'type': 'زيارة منزلية', 'time': '11:00'},
      {'name': 'محمود حسن', 'status': 'pending', 'type': 'داخل المركز', 'time': '11:30'},
      {'name': 'نورا أحمد', 'status': 'completed', 'type': 'زيارة منزلية', 'time': '12:00'},
      {'name': 'عمر خالد', 'status': 'pending', 'type': 'داخل المركز', 'time': '12:30'},
    ];

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
              TextButton(
                onPressed: () {},
                child: const Text(AppStrings.showAll, style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recentCases.map((c) => _buildRecentCaseItem(c)),
        ],
      ),
    );
  }

  Widget _buildRecentCaseItem(Map<String, String> caseData) {
    Color statusColor;
    String statusText;
    switch (caseData['status']) {
      case 'completed':
        statusColor = AppColors.statusCompleted;
        statusText = AppStrings.completed;
        break;
      case 'in_progress':
        statusColor = AppColors.statusInProgress;
        statusText = AppStrings.inProgress;
        break;
      default:
        statusColor = AppColors.statusPending;
        statusText = AppStrings.pending;
    }

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
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caseData['name'] ?? '',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${caseData['type']} • ${caseData['time']}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
