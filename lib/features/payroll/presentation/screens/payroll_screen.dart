import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../cubit/payroll_cubit.dart';
import '../cubit/payroll_state.dart';
import '../../data/models/payroll_model.dart';
import '../widgets/payroll_table.dart';
import '../widgets/salary_breakdown_card.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/pdf/report_service.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';
import '../../../../features/reports/presentation/screens/report_preview_screen.dart';
import '../../../../core/utils/ui_feedback.dart';

/// شاشة الرواتب - Payroll Management Screen
class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  PayrollModel? _selectedPayroll;

  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  @override
  void initState() {
    super.initState();
    context.read<PayrollCubit>().loadPayroll(
      year: _selectedYear,
      month: _selectedMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<PayrollCubit, PayrollState>(
        listener: (context, state) {
          if (state is PayrollActionSuccess) {
            UIFeedback.showSuccess(context, state.message);
          }
          if (state is PayrollError) {
            UIFeedback.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: AppSpacing.sectionGap),
                if (state is PayrollLoaded) ...[
                  _buildStatsRow(state),
                  const SizedBox(height: AppSpacing.sectionGap),
                ],
                Expanded(child: _buildContent(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final titleSize = ResponsiveHelper.getTitleFontSize(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('الرواتب', style: AppTypography.pageTitle.copyWith(fontSize: titleSize)),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => context.read<PayrollCubit>().loadPayroll(
                    year: _selectedYear,
                    month: _selectedMonth,
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                ),
              ],
            ),
            Text(
              (context.read<AuthCubit>().currentUser?.role.isAdmin ?? false) 
                ? 'إدارة وحساب رواتب الموظفين الشهرية' 
                : 'استعراض تفاصيل راتبك الشخصي ومستحقاتك',
              style: AppTypography.pageSubtitle.copyWith(
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              ),
            ),
          ],
        ),
        if (context.read<AuthCubit>().currentUser?.role.isAdmin ?? false)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Outside Case Fee Editor
              FutureBuilder<double>(
                future: SqliteService.instance.getOutsideCaseFee(),
                builder: (context, snapshot) {
                  final fee = snapshot.data ?? 15.0;
                  return TextButton.icon(
                    onPressed: () => _showFeeEditDialog(context, fee),
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: Text(
                      'بدل العملية: ${fee.toStringAsFixed(0)} E.P',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => context.read<PayrollCubit>().calculateMonthlyPayroll(
                  year: _selectedYear,
                  month: _selectedMonth,
                ),
                icon: const Icon(Icons.calculate_rounded, size: 20),
                label: Text(
                  isMobile ? 'حساب' : 'حساب الرواتب',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => context.read<PayrollCubit>().approveAllPayrolls(),
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text(
                    'اعتماد الرواتب',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _generatePayrollReport,
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 28),
                  tooltip: 'طباعة التقرير الشهري',
                ),
                IconButton(
                  onPressed: _generateIncomeReport,
                  icon: const Icon(Icons.summarize_rounded, color: AppColors.primary, size: 28),
                  tooltip: 'تفاصيل دخل العمليات',
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          const Text(
            'الفترة:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          // Month selector button
          _toolbarDropdown<int>(
            value: _selectedMonth,
            items: List.generate(12, (i) => DropdownMenuItem(
              value: i + 1,
              child: Text(_months[i]),
            )),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedMonth = v);
                context.read<PayrollCubit>().loadPayroll(year: _selectedYear, month: v);
              }
            },
          ),
          const SizedBox(width: 10),
          // Year selector button
          _toolbarDropdown<int>(
            value: _selectedYear,
            items: List.generate(5, (i) {
              final y = DateTime.now().year - 2 + i;
              return DropdownMenuItem(value: y, child: Text('$y'));
            }),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedYear = v);
                context.read<PayrollCubit>().loadPayroll(year: v, month: _selectedMonth);
              }
            },
          ),
          const Spacer(),
          // Selected period summary badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              '${_months[_selectedMonth - 1]} $_selectedYear',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildStatsRow(PayrollLoaded state) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 2.0 : 2.5,
      children: [
        _statCard(
          'إجمالي الرواتب',
          NumberFormatter.currency(state.totalSalaries),
          Icons.payments_rounded,
          AppColors.primary,
        ),
        _statCard(
          'عدد الموظفين',
          '${state.payrolls.length}',
          Icons.people_rounded,
          AppColors.secondary,
        ),
        _statCard(
          'إجمالي الساعات',
          NumberFormatter.hours(state.totalHours),
          Icons.access_time_rounded,
          AppColors.info,
        ),
        _statCard(
          'الحالة',
          state.payrolls.isEmpty ? 'لا يوجد' : _getOverallStatus(state),
          Icons.check_circle_rounded,
          AppColors.success,
        ),
      ],
    );
  }

  String _getOverallStatus(PayrollLoaded state) {
    if (state.payrolls.isEmpty) return 'لا يوجد';
    final allPaid = state.payrolls.every((p) => p.status == 'paid');
    final allApproved = state.payrolls.every((p) => p.status == 'approved' || p.status == 'paid');
    if (allPaid) return 'تم الدفع';
    if (allApproved) return 'معتمد';
    return 'مسودة';
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTypography.statValue.copyWith(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(title, style: AppTypography.statLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, PayrollState state) {
    if (state is PayrollLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is PayrollError) {
      return EmptyStateWidget.error(
        message: state.message,
        onRetry: () => context.read<PayrollCubit>().loadPayroll(
          year: _selectedYear,
          month: _selectedMonth,
        ),
      );
    }
    if (state is PayrollLoaded) {
      if (state.payrolls.isEmpty) {
        return EmptyStateWidget(
          icon: Icons.payments_rounded,
          title: 'لا توجد رواتب لهذا الشهر',
          subtitle: 'اضغط "حساب الرواتب" لحساب رواتب ${_months[_selectedMonth - 1]} $_selectedYear',
          actionLabel: 'حساب الرواتب',
          onAction: () => context.read<PayrollCubit>().calculateMonthlyPayroll(
            year: _selectedYear,
            month: _selectedMonth,
          ),
        );
      }

      // Desktop layout: show table full width and use Dialog for details
      final isDesktop = ResponsiveHelper.isDesktop(context);

      final user = context.read<AuthCubit>().currentUser;
      final isAdmin = user?.role.isAdmin ?? false;
      final filteredPayrolls = isAdmin 
          ? state.payrolls 
          : state.payrolls.where((p) => p.userId == user?.id).toList();

      if (filteredPayrolls.isEmpty && !isAdmin) {
         return EmptyStateWidget(
           icon: Icons.payments_rounded,
           title: 'لا يوجد بيانات راتب لك هذا الشهر',
           subtitle: 'سيقوم المسؤول بحساب الرواتب فور انتهاء الشهر',
         );
      }

      return PayrollTable(
        payrolls: filteredPayrolls,
        selectedId: _selectedPayroll?.id,
        topToolbar: _buildMonthSelector(),
        onSelect: (p) {
          setState(() => _selectedPayroll = p);
          if (isDesktop) {
            _showPayrollDetailDialog(context, p);
          } else {
            _showPayrollDetailSheet(context, p);
          }
        },
        onApprove: isAdmin ? (p) => _generateIncomeReport(
          nurseName: p.userName,
          onApproveAction: () => context.read<PayrollCubit>().approvePayroll(p.id),
        ) : null,
        onPay: isAdmin ? (p) => context.read<PayrollCubit>().markAsPaid(p.id) : null,
        onViewIncomeDetails: (p) => _generateIncomeReport(nurseName: p.userName),
      );
    }
    return const SizedBox.shrink();
  }

  void _showPayrollDetailDialog(BuildContext context, PayrollModel payroll) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
          child: SalaryBreakdownCard(
            payroll: payroll,
            onClose: () {
              Navigator.pop(context);
              setState(() => _selectedPayroll = null);
            },
            onEdit: (bonus, deductions, notes) {
              context.read<PayrollCubit>().updatePayrollExtras(
                payrollId: payroll.id,
                bonus: bonus,
                deductions: deductions,
                notes: notes,
              );
            },
          ),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _selectedPayroll = null);
    });
  }

  void _showPayrollDetailSheet(BuildContext context, PayrollModel payroll) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SalaryBreakdownCard(
                  payroll: payroll,
                  onClose: () => Navigator.pop(context),
                  onEdit: (bonus, deductions, notes) {
                    context.read<PayrollCubit>().updatePayrollExtras(
                      payrollId: payroll.id,
                      bonus: bonus,
                      deductions: deductions,
                      notes: notes,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generatePayrollReport() {
    final state = context.read<PayrollCubit>().state;
    if (state is! PayrollLoaded || state.payrolls.isEmpty) {
      UIFeedback.showWarning(context, 'لا توجد بيانات رواتب لإصدار تقرير بها');
      return;
    }

    final authState = context.read<AuthCubit>().state;
    String genBy = 'مدير النظام';
    if (authState is AuthAuthenticated) genBy = authState.user.name;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          title: 'تقرير مسير الرواتب - ${_months[_selectedMonth - 1]} $_selectedYear',
          fileName: 'Payroll_Report_$_selectedYear$_selectedMonth',
          buildReport: () => ReportService.instance.generatePayrollReportBytes(
            payrolls: state.payrolls,
            year: _selectedYear,
            month: _selectedMonth,
            generatedBy: genBy,
          ),
        ),
      ),
    );
  }

  void _generateIncomeReport({String? nurseName, VoidCallback? onApproveAction}) async {
    final state = context.read<PayrollCubit>().state;
    if (state is! PayrollLoaded) return;

    final authState = context.read<AuthCubit>().state;
    String genBy = 'مدير النظام';
    if (authState is AuthAuthenticated) genBy = authState.user.name;

    // Fetch cases for the report
    final cases = await context.read<PayrollCubit>().getMonthlyCases(_selectedYear, _selectedMonth);

    if (!mounted) return;

    final filteredCases = nurseName != null
        ? cases.where((c) => c.nurseName == nurseName).toList()
        : cases;

    if (filteredCases.isEmpty) {
      UIFeedback.showWarning(
        context, 
        nurseName != null 
          ? 'لا توجد عمليات مسجلة للممرض $nurseName هذا الشهر' 
          : 'لا توجد عمليات مسجلة لهذا الشهر'
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(
          title: nurseName != null 
            ? 'مراجعة دخل العمليات: $nurseName - ${_months[_selectedMonth - 1]} $_selectedYear'
            : 'تفاصيل دخل العمليات - ${_months[_selectedMonth - 1]} $_selectedYear',
          fileName: nurseName != null
            ? 'Income_${nurseName}_$_selectedYear$_selectedMonth'
            : 'Income_Details_$_selectedYear$_selectedMonth',
          extraActions: onApproveAction != null ? [
            ElevatedButton.icon(
              onPressed: () {
                onApproveAction();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('تأكيد اعتماد الراتب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] : null,
          buildReport: () => ReportService.instance.generateMonthlyIncomeReportBytes(
            cases: cases,
            year: _selectedYear,
            month: _selectedMonth,
            generatedBy: genBy,
            nurseName: nurseName,
          ),
        ),
      ),
    );
  }

  void _showFeeEditDialog(BuildContext context, double currentFee) {
    final controller = TextEditingController(text: currentFee.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل بدل العملية الخارجية', style: TextStyle(fontFamily: 'Cairo')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'المبلغ (E.P)',
            hintText: 'مثلاً: 15',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              final newFee = double.tryParse(controller.text);
              if (newFee != null) {
                await SqliteService.instance.saveOutsideCaseFee(newFee);
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {}); // Refresh header
                  UIFeedback.showSuccess(context, 'تم تحديث قيمة بدل العمليات الخارجية');
                }
              }
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

