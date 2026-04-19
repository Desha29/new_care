import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/buttons/icon_action_button.dart';
import '../../data/models/payroll_model.dart';

/// جدول الرواتب - Payroll Table Widget
class PayrollTable extends StatelessWidget {
  final List<PayrollModel> payrolls;
  final String? selectedId;
  final Function(PayrollModel) onSelect;
  final Function(PayrollModel) onApprove;
  final Function(PayrollModel) onPay;

  const PayrollTable({
    super.key,
    required this.payrolls,
    this.selectedId,
    required this.onSelect,
    required this.onApprove,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLg),
                topRight: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                _hc('الموظف', 3),
                _hc('الساعات', 2),
                _hc('الراتب الأساسي', 2),
                _hc('المكافآت', 1),
                _hc('الخصومات', 1),
                _hc('الصافي', 2),
                _hc('الحالة', 2),
                _hc('إجراءات', 2),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Table body
          Expanded(
            child: ListView.separated(
              itemCount: payrolls.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (_, i) => _buildRow(context, payrolls[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hc(String t, int f) => Expanded(
    flex: f,
    child: Text(t, style: AppTypography.tableHeader.copyWith(fontSize: 12)),
  );

  Widget _buildRow(BuildContext context, PayrollModel payroll, int index) {
    final isSelected = selectedId == payroll.id;

    return InkWell(
      onTap: () => onSelect(payroll),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : index.isEven
                  ? Colors.transparent
                  : AppColors.surfaceVariant.withValues(alpha: 0.3),
          border: isSelected
              ? Border(right: BorderSide(color: AppColors.primary, width: 3))
              : null,
        ),
        child: Row(
          children: [
            // الموظف
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      payroll.userName.isNotEmpty ? payroll.userName.substring(0, 1) : '?',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      payroll.userName,
                      style: AppTypography.tableCell.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // الساعات
            Expanded(
              flex: 2,
              child: Text(
                NumberFormatter.hours(payroll.totalHours),
                style: AppTypography.tableCell,
              ),
            ),
            // الراتب الأساسي
            Expanded(
              flex: 2,
              child: Text(
                NumberFormatter.currency(payroll.baseSalary),
                style: AppTypography.tableCell,
              ),
            ),
            // المكافآت
            Expanded(
              flex: 1,
              child: Text(
                payroll.bonus > 0 ? '+${NumberFormatter.compact(payroll.bonus)}' : '-',
                style: AppTypography.tableCell.copyWith(
                  color: payroll.bonus > 0 ? AppColors.success : AppColors.textHint,
                ),
              ),
            ),
            // الخصومات
            Expanded(
              flex: 1,
              child: Text(
                payroll.deductions > 0 ? '-${NumberFormatter.compact(payroll.deductions)}' : '-',
                style: AppTypography.tableCell.copyWith(
                  color: payroll.deductions > 0 ? AppColors.error : AppColors.textHint,
                ),
              ),
            ),
            // الصافي
            Expanded(
              flex: 2,
              child: Text(
                NumberFormatter.currency(payroll.netSalary),
                style: AppTypography.tableCell.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            // الحالة
            Expanded(
              flex: 2,
              child: _buildStatusBadge(payroll.status),
            ),
            // إجراءات
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  IconActionButton.view(
                    onPressed: () => onSelect(payroll),
                  ),
                  const SizedBox(width: 4),
                  if (payroll.status == 'draft')
                    IconActionButton(
                      icon: Icons.check_circle_rounded,
                      tooltip: 'اعتماد',
                      color: AppColors.success,
                      onPressed: () => onApprove(payroll),
                    ),
                  if (payroll.status == 'approved')
                    IconActionButton(
                      icon: Icons.payments_rounded,
                      tooltip: 'تسجيل الدفع',
                      color: AppColors.primary,
                      onPressed: () => onPay(payroll),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'approved':
        bgColor = AppColors.statusInProgressBg;
        textColor = AppColors.statusInProgress;
        label = 'معتمد';
        break;
      case 'paid':
        bgColor = AppColors.statusCompletedBg;
        textColor = AppColors.statusCompleted;
        label = 'تم الدفع';
        break;
      default:
        bgColor = AppColors.statusPendingBg;
        textColor = AppColors.statusPending;
        label = 'مسودة';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
