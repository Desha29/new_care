import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../logic/cubit/payroll_cubit.dart';
import '../../logic/cubit/payroll_state.dart';
import '../../data/models/payroll_model.dart';
import '../widgets/payroll_table.dart';
import '../widgets/salary_breakdown_card.dart';

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                backgroundColor: AppColors.success,
              ),
            );
          }
          if (state is PayrollError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                backgroundColor: AppColors.error,
              ),
            );
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
                _buildMonthSelector(),
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
              'إدارة وحساب رواتب الموظفين الشهرية',
              style: AppTypography.pageSubtitle.copyWith(
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: isMobile ? 'حساب' : 'حساب الرواتب',
              icon: Icons.calculate_rounded,
              onPressed: () => context.read<PayrollCubit>().calculateMonthlyPayroll(
                year: _selectedYear,
                month: _selectedMonth,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text('الفترة:', style: AppTypography.sectionTitle.copyWith(fontSize: 14)),
          const SizedBox(width: 16),
          // Month dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedMonth,
                style: AppTypography.tableCell.copyWith(color: AppColors.textPrimary),
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
            ),
          ),
          const SizedBox(width: 12),
          // Year dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                style: AppTypography.tableCell.copyWith(color: AppColors.textPrimary),
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
            ),
          ),
          const Spacer(),
          // Period display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_months[_selectedMonth - 1]} $_selectedYear',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
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

      // Two-panel layout: table + detail
      final isDesktop = ResponsiveHelper.isDesktop(context);
      if (isDesktop && _selectedPayroll != null) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: PayrollTable(
                payrolls: state.payrolls,
                selectedId: _selectedPayroll?.id,
                onSelect: (p) => setState(() => _selectedPayroll = p),
                onApprove: (p) => context.read<PayrollCubit>().approvePayroll(p.id),
                onPay: (p) => context.read<PayrollCubit>().markAsPaid(p.id),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: SalaryBreakdownCard(payroll: _selectedPayroll!),
            ),
          ],
        );
      }

      return PayrollTable(
        payrolls: state.payrolls,
        selectedId: _selectedPayroll?.id,
        onSelect: (p) => setState(() => _selectedPayroll = p),
        onApprove: (p) => context.read<PayrollCubit>().approvePayroll(p.id),
        onPay: (p) => context.read<PayrollCubit>().markAsPaid(p.id),
      );
    }
    return const SizedBox.shrink();
  }
}
