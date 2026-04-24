import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/services/pdf/report_service.dart';
import '../../../reports/presentation/screens/report_preview_screen.dart';
import '../cubit/financials_cubit.dart';

class FinancialsHeader extends StatelessWidget {
  final FinancialsLoaded state;
  final VoidCallback onAddExpense;

  const FinancialsHeader({
    super.key,
    required this.state,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final titleSize = ResponsiveHelper.getTitleFontSize(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
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
              onPressed: () {
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
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: Text(
                isMobile ? 'PDF' : 'تقرير PDF مجمع',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
    );
  }
}
