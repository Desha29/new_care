import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../data/models/payroll_model.dart';

/// بطاقة تفاصيل الراتب - Salary Breakdown Card
/// تعرض تفاصيل راتب موظف واحد
class SalaryBreakdownCard extends StatelessWidget {
  final PayrollModel payroll;
  final VoidCallback? onClose;
  final Function(double? bonus, double? deductions, String? notes)? onEdit;

  const SalaryBreakdownCard({
    super.key,
    required this.payroll,
    this.onClose,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Header ===
            _buildHeader(),
            const Divider(height: 1, color: AppColors.border),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Employee Info ===
                  _buildEmployeeInfo(),
                  const SizedBox(height: 20),

                  // === Attendance Summary ===
                  _buildSectionTitle('ملخص الحضور', Icons.access_time_rounded),
                  const SizedBox(height: 12),
                  _buildInfoRow('أيام العمل', '${payroll.totalDays} يوم'),
                  _buildInfoRow('أيام الغياب', '${payroll.absentDays} يوم',
                      valueColor: payroll.absentDays > 0 ? AppColors.error : null),
                  _buildInfoRow('إجمالي الساعات', NumberFormatter.hours(payroll.totalHours)),
                  _buildInfoRow('نسبة الحضور', NumberFormatter.percentage(payroll.attendanceRate),
                      valueColor: payroll.attendanceRate >= 90 ? AppColors.success : AppColors.warning),
                  _buildInfoRow('سعر الساعة', NumberFormatter.currency(payroll.hourlyRate)),

                  const Divider(height: 32),

                  // === Financial Breakdown ===
                  _buildSectionTitle('التفاصيل المالية', Icons.payments_rounded),
                  const SizedBox(height: 12),
                  _buildFinancialRow(context, 'الراتب الأساسي', payroll.baseSalary, isPositive: true),
                  if (payroll.outsideCasesFees > 0)
                    _buildFinancialRow(context, 'عمليات خارجية', payroll.outsideCasesFees, isPositive: true),
                  _buildFinancialRow(
                    context, 
                    'المكافآت والزيادات', 
                    payroll.bonus, 
                    isPositive: true,
                    onEdit: onEdit != null ? () => _showEditDialog(context, 'bonus') : null,
                  ),
                  _buildFinancialRow(
                    context, 
                    'الخصومات والجزاءات', 
                    payroll.deductions, 
                    isPositive: false,
                    onEdit: onEdit != null ? () => _showEditDialog(context, 'deductions') : null,
                  ),

                  const SizedBox(height: 16),

                  // === Net Salary ===
                  _buildNetSalary(),

                  if (payroll.notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildNotes(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLg),
          topRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تفاصيل الراتب', style: AppTypography.sectionTitle.copyWith(fontSize: 15)),
                Text(
                  payroll.periodTitle,
                  style: AppTypography.cardBody,
                ),
              ],
            ),
          ),
          _buildStatusChip(payroll.status),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              payroll.userName.isNotEmpty ? payroll.userName.substring(0, 1) : '?',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payroll.userName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'فترة الرواتب: ${payroll.periodTitle}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTypography.sectionTitle.copyWith(fontSize: 14)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.cardBody),
          Text(
            value,
            style: AppTypography.tableCell.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    BuildContext context, 
    String label, 
    double amount, {
    required bool isPositive,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.tableCell),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isPositive ? '+' : '-'} ${NumberFormatter.currency(amount)}',
                style: AppTypography.tableCell.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.edit_rounded, 
                      size: 14, 
                      color: isPositive ? AppColors.success : AppColors.error
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetSalary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: AppColors.success, size: 22),
              const SizedBox(width: 10),
              Text(
                'صافي الراتب',
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 15,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          Text(
            NumberFormatter.currency(payroll.netSalary),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('ملاحظات', style: AppTypography.cardBody.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            payroll.notes,
            style: AppTypography.tableCell.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        bgColor = AppColors.statusInProgressBg;
        textColor = AppColors.statusInProgress;
        label = 'معتمد';
        icon = Icons.verified_rounded;
        break;
      case 'paid':
        bgColor = AppColors.statusCompletedBg;
        textColor = AppColors.statusCompleted;
        label = 'مدفوع';
        icon = Icons.check_circle_rounded;
        break;
      default:
        bgColor = AppColors.statusPendingBg;
        textColor = AppColors.statusPending;
        label = 'مسودة';
        icon = Icons.edit_note_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
  void _showEditDialog(BuildContext context, String field) {
    final controller = TextEditingController(
      text: (field == 'bonus' ? payroll.bonus : payroll.deductions).toStringAsFixed(0),
    );
    final notesController = TextEditingController(text: payroll.notes);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          field == 'bonus' ? 'تعديل المكافآت والزيادات' : 'تعديل الخصومات والجزاءات',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ (E.P)',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                onEdit!(
                  field == 'bonus' ? val : null,
                  field == 'deductions' ? val : null,
                  notesController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

