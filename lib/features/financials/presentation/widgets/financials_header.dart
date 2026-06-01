import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/services/reports/report_service.dart';
import '../../../../core/services/excel/excel_service.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../reports/presentation/screens/report_preview_screen.dart';
import '../cubit/financials_cubit.dart';

import '../../../../core/widgets/search_bar_widget.dart';

class FinancialsHeader extends StatelessWidget {
  final FinancialsLoaded state;
  final VoidCallback onAddExpense;

  const FinancialsHeader({
    super.key,
    required this.state,
    required this.onAddExpense,
  });

  void _generateFinancialReport(BuildContext context) {
    final now = DateTime.now();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          title: 'التقرير المالي - ${DateFormat('MMMM yyyy', 'ar').format(now)}',
          fileName: 'Financial_Report_${DateFormat('yyyy_MM').format(now)}',
          buildReport: () => ReportService.instance.generateFinancialReportBytes(
            cases: state.cases,
            expenses: state.expenses,
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
          onExportExcel: () async {
            final success = await ExcelService.instance.exportFinancialsToExcel(
              cases: state.cases,
              expenses: state.expenses,
              start: DateTime(now.year, now.month, 1),
              end: now,
            );
            if (context.mounted) {
              if (success) {
                UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
              } else {
                UIFeedback.showError(context, 'فشل تصدير ملف Excel أو تم إلغاؤه');
              }
            }
          },
        ),
      ),
    );
  }

  void _showAllReportsMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.assessment_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('جميع التقارير المالية', style: TextStyle(fontFamily: 'Cairo', fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _reportOption(ctx, 'التقرير المالي الشامل', Icons.account_balance_rounded, () {
              Navigator.pop(ctx);
              _generateFinancialReport(context);
            }),
            const Divider(),
            _reportOption(ctx, 'تفاصيل دخل العمليات', Icons.receipt_long_rounded, () async {
              final now = DateTime.now();
              final title = 'تفاصيل دخل العمليات - ${DateFormat('MMMM yyyy', 'ar').format(now)}';
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportPreviewScreen(
                    title: title,
                    fileName: 'Income_Details_${now.year}_${now.month}',
                    buildReport: () => ReportService.instance.generateMonthlyIncomeReportBytes(
                      cases: state.cases,
                      year: now.year,
                      month: now.month,
                      generatedBy: 'مدير النظام',
                    ),
                    onExportExcel: () async {
                      final success = await ExcelService.instance.exportIncomeDetailsToExcel(
                        cases: state.cases,
                        year: now.year,
                        month: now.month,
                      );
                      if (context.mounted) {
                        UIFeedback.showSuccess(context, success ? 'تم التصدير بنجاح' : 'فشل التصدير');
                      }
                    },
                  ),
                ),
              );
            }),
            const Divider(),
            _reportOption(ctx, 'تصدير Excel فقط', Icons.table_chart_rounded, () async {
              Navigator.pop(ctx);
              final now = DateTime.now();
              final success = await ExcelService.instance.exportFinancialsToExcel(
                cases: state.cases,
                expenses: state.expenses,
                start: DateTime(now.year, now.month, 1),
                end: now,
              );
              if (context.mounted) {
                UIFeedback.showSuccess(context, success ? 'تم التصدير بنجاح' : 'فشل التصدير');
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _reportOption(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(label, style: const TextStyle(fontFamily: 'Cairo')),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final titleSize = ResponsiveHelper.getTitleFontSize(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التقارير المالية',
                  style: AppTypography.pageTitle.copyWith(fontSize: titleSize),
                ),
                Text(
                  'إدارة الدخل والمصروفات والأرباح - ${DateFormat('MMMM yyyy', 'ar').format(DateTime.now())}',
                  style: AppTypography.pageSubtitle.copyWith(
                    fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _generateFinancialReport(context),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text(
                    isMobile ? 'تقرير' : 'تقرير مالي',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAllReportsMenu(context),
                  icon: const Icon(Icons.more_horiz_rounded, size: 18),
                  label: Text(
                    isMobile ? '' : 'جميع التقارير',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    foregroundColor: AppColors.secondary,
                    side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.3)),
                  ),
                ),
                PrimaryButton(
                  label: isMobile ? 'إضافة' : 'إضافة مصروف',
                  icon: Icons.add_rounded,
                  onPressed: onAddExpense,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        SearchBarWidget(
          hintText: 'البحث في المصروفات...',
          onChanged: (v) => context.read<FinancialsCubit>().searchExpenses(v),
          maxWidth: double.infinity,
        ),
      ],
    );
  }
}
