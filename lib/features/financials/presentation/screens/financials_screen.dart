import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/financials_repository.dart';
import '../../data/models/expense_model.dart';
import '../cubit/financials_cubit.dart';
import '../widgets/financials_header.dart';
import '../widgets/financials_stats.dart';
import '../widgets/expenses_table.dart';
import '../widgets/income_summary.dart';
import '../widgets/add_expense_dialog.dart';
import '../../../../core/utils/ui_feedback.dart';

class FinancialsScreen extends StatelessWidget {
  const FinancialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FinancialsCubit(financialsRepository: sl<IFinancialsRepository>())..loadFinancials(),
      child: const _FinancialsView(),
    );
  }
}

class _FinancialsView extends StatelessWidget {
  const _FinancialsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<FinancialsCubit, FinancialsState>(
        listener: (context, state) {
          if (state is FinancialsError) {
            UIFeedback.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is FinancialsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FinancialsLoaded) {
            final padding = ResponsiveHelper.getScreenPadding(context);
            final isSmall = !ResponsiveHelper.isDesktop(context);

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FinancialsHeader(
                    state: state,
                    onAddExpense: () => AddExpenseDialog.show(context, context.read<FinancialsCubit>()),
                  ),
                  const SizedBox(height: 24),
                  FinancialsStats(state: state),
                  const SizedBox(height: 24),
                  if (isSmall) ...[
                    ExpensesTable(
                      state: state,
                      onDelete: (e) => _confirmDelete(context, e),
                      onAdd: () => AddExpenseDialog.show(context, context.read<FinancialsCubit>()),
                    ),
                    const SizedBox(height: 20),
                    IncomeSummary(state: state),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ExpensesTable(
                            state: state,
                            onDelete: (e) => _confirmDelete(context, e),
                            onAdd: () => AddExpenseDialog.show(context, context.read<FinancialsCubit>()),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: IncomeSummary(state: state),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }

          return const Center(child: Text('حدث خطأ في عرض البيانات المادية'));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseModel e) {
    final cubit = context.read<FinancialsCubit>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف مصروف', style: TextStyle(fontFamily: 'Cairo')),
        content: Text(
          'هل أنت متأكد من حذف مصروف "${e.label}" بمبلغ ${e.amount}؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              cubit.deleteExpense(e.id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
