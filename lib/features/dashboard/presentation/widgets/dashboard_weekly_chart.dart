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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxY = (weeklyCounts.isNotEmpty
              ? (weeklyCounts.reduce((a, b) => a > b ? a : b) + 2)
              : 10);
          
          // Calculate interval to have roughly 5-6 lines
          final double interval = (maxY / 5).ceilToDouble();

          return Column(
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
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.primaryDark,
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final now = DateTime.now();
                          final date = now.subtract(
                            Duration(days: 6 - group.x.toInt()),
                          );
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
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value > 6) return const SizedBox.shrink();
                            final now = DateTime.now();
                            final date = now.subtract(
                              Duration(days: 6 - value.toInt()),
                            );
                            final dayName = DateFormat('E', 'ar').format(date);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                dayName,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint,
                                ),
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
                            if (value % interval != 0) return const SizedBox.shrink();
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
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(color: AppColors.borderLight, strokeWidth: 1);
                      },
                    ),
                    barGroups: List.generate(
                      7,
                      (i) => _makeBarGroup(
                        i,
                        i < weeklyCounts.length ? weeklyCounts[i] : 0.0,
                        barWidth: constraints.maxWidth / 14,
                        maxRange: maxY,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y,
      {required double barWidth, required double maxRange}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primary,
          width: barWidth.clamp(12, 24),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxRange,
            color: AppColors.primary.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }
}
