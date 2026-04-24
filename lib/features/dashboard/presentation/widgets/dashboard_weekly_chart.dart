import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class DashboardWeeklyChart extends StatelessWidget {
  final List<double> weeklyCounts;

  const DashboardWeeklyChart({super.key, required this.weeklyCounts});

  @override
  Widget build(BuildContext context) {
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
                maxY: (weeklyCounts.isNotEmpty ? (weeklyCounts.reduce((a, b) => a > b ? a : b) + 5) : 10),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primaryDark,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final now = DateTime.now();
                      final date = now.subtract(Duration(days: 6 - group.x.toInt()));
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
                  (i) => _makeBarGroup(i, i < weeklyCounts.length ? weeklyCounts[i] : 0.0),
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
          color: AppColors.primary,
          width: 14,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: AppColors.primary.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }
}
