import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/stat_card.dart';

class StatsCardsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatsCardsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
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
          value: '${stats['todayCases'] ?? 0}',
          icon: Icons.medical_services_rounded,
          color: AppColors.info,
          subtitle: 'حالة اليوم',
        ),
        StatCard(
          title: AppStrings.totalRevenue,
          value: NumberFormatter.currency(((stats['todayRevenue'] ?? 0.0) as double)),
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.success,
          subtitle: 'إيرادات اليوم',
        ),
        StatCard(
          title: 'توزيع الحالات',
          value: '${(stats['todayCases'] ?? 0) > 0 ? (((stats['completedCases'] ?? 0) / (stats['todayCases'] ?? 1)) * 100).toStringAsFixed(0) : 0}%',
          icon: Icons.pie_chart_rounded,
          color: AppColors.secondary,
          subtitle: 'نسبة الإنجاز اليومي',
        ),
        StatCard(
          title: AppStrings.availableNurses,
          value: '${stats['availableNurses'] ?? 0}',
          icon: Icons.person_rounded,
          color: const Color(0xFF8B5CF6),
          subtitle: 'ممرض نشط',
        ),
      ],
    );
  }
}
