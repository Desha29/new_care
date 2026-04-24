import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/stat_card.dart';
import '../cubit/financials_cubit.dart';

class FinancialsStats extends StatelessWidget {
  final FinancialsLoaded state;

  const FinancialsStats({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.isMobile(context) ? 1 : 3;
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: ResponsiveHelper.isMobile(context) ? 2.8 : 2.0,
      children: [
        StatCard(
          title: 'إجمالي الدخل',
          value: '${state.totalIncome.toStringAsFixed(0)} ${AppStrings.currency}',
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
          subtitle: 'من الحالات المؤكدة',
        ),
        StatCard(
          title: 'إجمالي المصروفات',
          value: '${state.totalExpenses.toStringAsFixed(0)} ${AppStrings.currency}',
          icon: Icons.trending_down_rounded,
          color: AppColors.error,
          subtitle: 'تكاليف وشراء مستلزمات',
        ),
        StatCard(
          title: 'صافي الربح',
          value: '${state.netProfit.toStringAsFixed(0)} ${AppStrings.currency}',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.primary,
          subtitle: 'الأرباح القابلة للتوزيع',
        ),
      ],
    );
  }
}
