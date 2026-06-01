import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../data/models/payroll_model.dart';
import '../../data/models/advance_model.dart';

/// بطاقة تفاصيل الراتب - Salary Breakdown Card
/// تعرض تفاصيل راتب موظف واحد
class SalaryBreakdownCard extends StatelessWidget {
  final PayrollModel payroll;
  final VoidCallback? onClose;
  final Function(double? bonus, double? deductions, double? salafa, String? notes)? onEdit;
  /// Callback to fetch advances for this payroll's user/month
  final Future<List<AdvanceModel>> Function()? onLoadAdvances;
  /// Callback to add a new advance
  final Future<void> Function(double amount, DateTime date, String notes)? onAddAdvance;
  /// Callback to delete an advance by ID
  final Future<void> Function(String advanceId)? onDeleteAdvance;

  const SalaryBreakdownCard({
    super.key,
    required this.payroll,
    this.onClose,
    this.onEdit,
    this.onLoadAdvances,
    this.onAddAdvance,
    this.onDeleteAdvance,
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
                  _buildFinancialRow(
                    context, 
                    'السلفة المستقطعة', 
                    payroll.salafa, 
                    isPositive: false,
                    onEdit: onLoadAdvances != null ? () => _showAdvancesManagementDialog(context) : null,
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
                  null,
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

  /// عرض نافذة إدارة السلف - Show advances management dialog
  void _showAdvancesManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _AdvancesManagementDialog(
        userName: payroll.userName,
        onLoadAdvances: onLoadAdvances!,
        onAddAdvance: onAddAdvance,
        onDeleteAdvance: onDeleteAdvance,
      ),
    );
  }
}

/// نافذة إدارة السلف - Advances Management Dialog
class _AdvancesManagementDialog extends StatefulWidget {
  final String userName;
  final Future<List<AdvanceModel>> Function() onLoadAdvances;
  final Future<void> Function(double amount, DateTime date, String notes)? onAddAdvance;
  final Future<void> Function(String advanceId)? onDeleteAdvance;

  const _AdvancesManagementDialog({
    required this.userName,
    required this.onLoadAdvances,
    this.onAddAdvance,
    this.onDeleteAdvance,
  });

  @override
  State<_AdvancesManagementDialog> createState() => _AdvancesManagementDialogState();
}

class _AdvancesManagementDialogState extends State<_AdvancesManagementDialog> {
  List<AdvanceModel> _advances = [];
  bool _loading = true;
  bool _showAddForm = false;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAdvances();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvances() async {
    setState(() => _loading = true);
    try {
      final advances = await widget.onLoadAdvances();
      if (mounted) {
        setState(() {
          _advances = advances;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _totalAmount => _advances.fold(0.0, (sum, a) => sum + a.amount);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.money_off_rounded, color: AppColors.error, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إدارة السلف',
                          style: TextStyle(
                            fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            // Total badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إجمالي السلف: ${_advances.length} سلفة',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    NumberFormatter.currency(_totalAmount),
                    style: const TextStyle(
                      fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Content
            Flexible(
              child: _loading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ))
                  : _advances.isEmpty && !_showAddForm
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.money_off_rounded, size: 48, color: AppColors.textHint.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text(
                                'لا توجد سلف مسجلة لهذا الشهر',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: [
                            if (_showAddForm) _buildAddForm(),
                            ..._advances.map((adv) => _buildAdvanceItem(adv)),
                          ],
                        ),
            ),

            // Bottom actions
            if (widget.onAddAdvance != null) ...[
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAddForm = !_showAddForm;
                        if (!_showAddForm) {
                          _amountController.clear();
                          _notesController.clear();
                          _selectedDate = DateTime.now();
                        }
                      });
                    },
                    icon: Icon(_showAddForm ? Icons.close_rounded : Icons.add_rounded, size: 20),
                    label: Text(
                      _showAddForm ? 'إلغاء الإضافة' : 'إضافة سلفة جديدة',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showAddForm ? AppColors.textSecondary : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'سلفة جديدة',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'المبلغ (E.P)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money_rounded),
              isDense: true,
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(DateTime.now().year - 1),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ملاحظات (اختياري)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitAdvance,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('حفظ السلفة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAdvance() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    await widget.onAddAdvance!(amount, _selectedDate, _notesController.text);
    _amountController.clear();
    _notesController.clear();
    _selectedDate = DateTime.now();
    setState(() => _showAddForm = false);
    await _loadAdvances();
  }

  Widget _buildAdvanceItem(AdvanceModel advance) {
    final dateStr = '${advance.date.year}-${advance.date.month.toString().padLeft(2, '0')}-${advance.date.day.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.money_off_rounded, color: AppColors.error, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NumberFormatter.currency(advance.amount),
                  style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error,
                  ),
                ),
                Text(
                  dateStr + (advance.notes.isNotEmpty ? ' — ${advance.notes}' : ''),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.onDeleteAdvance != null)
            IconButton(
              onPressed: () => _confirmDelete(advance),
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
              tooltip: 'حذف',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AdvanceModel advance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف السلفة', style: TextStyle(fontFamily: 'Cairo')),
        content: Text(
          'هل تريد حذف السلفة بمبلغ ${NumberFormatter.currency(advance.amount)}؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.onDeleteAdvance!(advance.id);
      await _loadAdvances();
    }
  }
}

