import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/financials_cubit.dart';

class IncomeSummary extends StatelessWidget {
  final FinancialsLoaded state;

  const IncomeSummary({super.key, required this.state});

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
            'نظرة على الدخل',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _incomeRow(
            'حالات اليوم',
            state.cases
                .where((c) => c.caseDate.day == DateTime.now().day)
                .length
                .toString(),
            AppColors.primary,
          ),
          const SizedBox(height: 12),
          _incomeRow(
            'إجمالي الحالات',
            state.cases.length.toString(),
            AppColors.success,
          ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          const Text(
            'توزيع الدخل حسب نوع الحالة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _progressRow(
            'داخل المركز',
            state.cases.where((c) => c.caseType.name == 'inCenter').length,
            state.cases.length,
            AppColors.info,
          ),
          const SizedBox(height: 10),
          _progressRow(
            'زيارات منزلية',
            state.cases.where((c) => c.caseType.name == 'homeVisit').length,
            state.cases.length,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _incomeRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _progressRow(String label, int count, int total, Color color) {
    double pr = total == 0 ? 0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: pr,
          color: color,
          backgroundColor: color.withValues(alpha: 0.1),
          minHeight: 6,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}

