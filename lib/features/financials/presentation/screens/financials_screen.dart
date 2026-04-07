import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../logic/cubit/financials_cubit.dart';
import '../../data/models/expense_model.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinancialsScreen extends StatelessWidget {
  const FinancialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FinancialsCubit()..loadFinancials(),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is FinancialsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is FinancialsLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, state),
                  const SizedBox(height: 24),
                  _buildStats(state),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildExpensesTable(context, state)),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: _buildIncomeSummary(state)),
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

  Widget _buildHeader(BuildContext context, FinancialsLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'التقارير المالية',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              'إدارة الدخل والمصروفات والأرباح - ${DateFormat('MMMM yyyy', 'ar').format(DateTime.now())}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => ReportService.instance.generateFinancialReport(
                cases: state.cases,
                expenses: state.expenses,
                start: DateTime.now().subtract(const Duration(days: 30)),
                end: DateTime.now(),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('تقرير PDF مجمع', style: TextStyle(fontFamily: 'Cairo')),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddExpenseDialog(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('إضافة مصروف', style: TextStyle(fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(FinancialsLoaded state) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'إجمالي الدخل',
            value: '${state.totalIncome.toStringAsFixed(0)} ${AppStrings.currency}',
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            subtitle: 'من الحالات المؤكدة',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'إجمالي المصروفات',
            value: '${state.totalExpenses.toStringAsFixed(0)} ${AppStrings.currency}',
            icon: Icons.trending_down_rounded,
            color: AppColors.error,
            subtitle: 'تكاليف وشراء مستلزمات',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'صافي الربح',
            value: '${state.netProfit.toStringAsFixed(0)} ${AppStrings.currency}',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.primary,
            subtitle: 'الأرباح القابلة للتوزيع',
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesTable(BuildContext context, FinancialsLoaded state) {
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
          const Text('سجل المصروفات', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (state.expenses.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('لا توجد مصروفات مسجلة حالياً', style: TextStyle(fontFamily: 'Cairo'))))
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
                        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.payment_rounded, color: AppColors.error, size: 18),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.label, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(e.category, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${e.amount} ${AppStrings.currency}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.error)),
                          Text(DateFormat('dd/MM/yyyy').format(e.date), style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textHint)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _confirmDelete(context, e),
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textHint, size: 20),
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

  Widget _buildIncomeSummary(FinancialsLoaded state) {
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
          const Text('نظرة على الدخل', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _incomeRow('حالات اليوم', state.cases.where((c) => c.caseDate.day == DateTime.now().day).length.toString(), AppColors.primary),
          const SizedBox(height: 12),
          _incomeRow('حالات مكتملة', state.cases.where((c) => c.status.name == 'completed').length.toString(), AppColors.success),
          const SizedBox(height: 12),
          _incomeRow('إجمالي الحالات', state.cases.length.toString(), AppColors.secondary),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          const Text('توزيع الدخل حسب نوع الحالة', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          // توزيع مبسط كنسبة
          _progressRow('داخل المركز', state.cases.where((c) => c.caseType.name == 'inCenter').length, state.cases.length, AppColors.info),
          const SizedBox(height: 10),
          _progressRow('زيارات منزلية', state.cases.where((c) => c.caseType.name == 'homeVisit').length, state.cases.length, AppColors.warning),
        ],
      ),
    );
  }

  Widget _incomeRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: color)),
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
            Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            Text('$count', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: pr, color: color, backgroundColor: color.withValues(alpha: 0.1), minHeight: 6, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final cubit = context.read<FinancialsCubit>();
    final formKey = GlobalKey<FormState>();
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String category = 'مرتبات';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة مصروف جديد', style: TextStyle(fontFamily: 'Cairo')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: category,
                items: ['مرتبات', 'إيجار', 'مستلزمات طبية', 'كهرباء ومياه', 'صيانة', 'أخرى'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
                onChanged: (v) => category = v!,
                decoration: const InputDecoration(labelText: 'التصنيف'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'الوصف أو البند'),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ'),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'مبلغ غير صحيح' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final user = FirebaseAuth.instance.currentUser;
                final expense = ExpenseModel(
                  id: FirebaseService.instance.generateId(),
                  category: category,
                  label: labelCtrl.text.trim(),
                  amount: double.parse(amountCtrl.text),
                  date: DateTime.now(),
                  createdBy: user?.uid ?? 'system',
                  notes: noteCtrl.text.trim(),
                );
                cubit.addExpense(expense);
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseModel e) {
    final cubit = context.read<FinancialsCubit>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف مصروف', style: TextStyle(fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد من حذف مصروف "${e.label}" بمبلغ ${e.amount}؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(onPressed: () {
            cubit.deleteExpense(e.id);
            Navigator.pop(ctx);
          }, child: const Text('حذف', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }
}
