import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/buttons/icon_action_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../data/models/case_model.dart';
import '../../logic/cubit/cases_cubit.dart';
import '../../../invoice/presentation/screens/invoice_preview_screen.dart';
import 'case_form_dialog.dart';

class CasesTable extends StatelessWidget {
  final List<CaseModel> cases;

  const CasesTable({super.key, required this.cases});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: cases.isEmpty
                ? EmptyStateWidget.cases(
                    onAction: () => _showCaseDialog(context),
                  )
                : ListView.separated(
                    itemCount: cases.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (context, index) =>
                        _buildTableRow(context, cases[index], index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          _headerCell('المريض / العميل', 3),
          _headerCell('الممرض المسئول', 2),
          _headerCell('نوع الحالة', 2),
          _headerCell('إجمالي السعر', 2),
          _headerCell('الإجراءات', 2),
        ],
      ),
    );
  }

  Widget _headerCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, CaseModel c, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: index.isEven
          ? Colors.transparent
          : AppColors.surfaceVariant.withValues(alpha: 0.2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.patientName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (c.patientPhone.isNotEmpty)
                  Text(
                    c.patientPhone,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              c.nurseName.isNotEmpty ? c.nurseName : '-',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(c.caseType.icon, size: 14, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  c.caseType.label,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${c.totalPrice.toStringAsFixed(0)} ${AppStrings.currency}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconActionButton(
                  icon: Icons.receipt_long_rounded,
                  tooltip: 'عرض الفاتورة',
                  color: AppColors.success,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoicePreviewScreen(caseData: c),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconActionButton.edit(
                  onPressed: () => _showCaseDialog(context, caseData: c),
                ),
                const SizedBox(width: 8),
                IconActionButton.delete(
                  onPressed: () => _confirmDelete(context, c),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCaseDialog(BuildContext context, {CaseModel? caseData}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [BlocProvider.value(value: context.read<CasesCubit>())],
        child: CaseFormDialog(caseData: caseData),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CaseModel c) {
    ConfirmDialog.show(
      context,
      title: 'حذف الحالة',
      message:
          'هل أنت متأكد من حذف حالة المريض "${c.patientName}"؟ لا يمكن التراجع عن هذا الإجراء.',
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<CasesCubit>().deleteCase(c);
      }
    });
  }
}
