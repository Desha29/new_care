import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/buttons/icon_action_button.dart';
import '../../data/models/expense_model.dart';
import '../cubit/financials_cubit.dart';

class ExpensesTable extends StatelessWidget {
  final FinancialsLoaded state;
  final Function(ExpenseModel) onDelete;
  final VoidCallback onAdd;

  const ExpensesTable({
    super.key,
    required this.state,
    required this.onDelete,
    required this.onAdd,
  });

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
            'سجل المصروفات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (state.expenses.isEmpty)
            EmptyStateWidget(
              icon: Icons.receipt_long_rounded,
              title: 'لا توجد مصروفات سجلت',
              subtitle: 'يمكنك إضافة مصروفات جديدة لتتبع التكاليف',
              actionLabel: 'إضافة مصروف',
              onAction: onAdd,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.expenses.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, i) {
                final e = state.expenses[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.payment_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.label,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              e.category,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${e.amount} ${AppStrings.currency}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(e.date),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconActionButton.delete(
                        onPressed: () => onDelete(e),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
