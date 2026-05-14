import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';

class DashboardKpiMetrics extends StatelessWidget {
  final Map<String, dynamic> stats;

  const DashboardKpiMetrics({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalCases = (stats['todayCases'] ?? 0) as int;
    final completedCases = (stats['completedCases'] ?? 0) as int;
    final availableNurses = (stats['availableNurses'] ?? 0) as int;
    final todayRevenue = (stats['todayRevenue'] ?? 0.0) as double;

    // حساب المقاييس
    final completionRate = totalCases > 0 ? (completedCases / totalCases) : 0.0;
    final avgCaseValue = totalCases > 0 ? todayRevenue / totalCases : 0.0;
    final efficiency = availableNurses > 0 ? totalCases / availableNurses : 0.0;

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
            'مقاييس الكفاءة والتشغيل',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildKpiItem(
            'معدل الإنجاز اليومي',
            '${(completionRate * 100).toStringAsFixed(1)}%',
            completionRate,
            AppColors.success,
            Icons.task_alt_rounded,
          ),
          const Divider(height: 32),
          _buildKpiItem(
            'متوسط قيمة الحالة',
            NumberFormatter.currency(avgCaseValue),
            avgCaseValue > 1000 ? 1.0 : avgCaseValue / 1000,
            AppColors.info,
            Icons.payments_rounded,
          ),
          const Divider(height: 32),
          _buildKpiItem(
            'معدل الحالات لكل ممرض',
            '${efficiency.toStringAsFixed(1)} حالة',
            efficiency > 10 ? 1.0 : efficiency / 10,
            AppColors.secondary,
            Icons.speed_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(
    String label,
    String value,
    double progress,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: color.withValues(alpha: 0.1),
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

