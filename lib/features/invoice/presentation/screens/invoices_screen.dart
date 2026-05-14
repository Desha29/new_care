import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/pdf/report_service.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/dialogs/custom_date_range_dialog.dart';
import '../../../cases/presentation/cubit/cases_cubit.dart';
import '../../../cases/presentation/cubit/cases_state.dart';
import '../../../payroll/presentation/cubit/payroll_cubit.dart';
import '../../../payroll/presentation/cubit/payroll_state.dart';
import '../../../payroll/data/models/payroll_model.dart';
import '../widgets/invoice_card.dart';
import '../widgets/invoice_preview_dialog.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _searchQuery = '';
  int _selectedTab = 0; // 0: Invoices, 1: Nursing Hours
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final casesCubit = context.read<CasesCubit>();
    final payrollCubit = context.read<PayrollCubit>();

    // Load payroll for the selected month
    payrollCubit.loadPayroll(
      month: _selectedMonth.month,
      year: _selectedMonth.year,
    );

    // Initial cases load (usually defaults to today or all depending on screen context)
    // Here we ensure it's synced with the view
    casesCubit.loadCases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: BlocBuilder<CasesCubit, CasesState>(
        builder: (context, casesState) {
          return CustomScrollView(
            slivers: [
              // Premium Header Sliver
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildTopHeader(context, casesState),
                      const SizedBox(height: 32),
                      _buildTabToggle(),
                      const SizedBox(height: 24),
                      _buildSearchAndFilters(context, casesState),
                    ],
                  ),
                ),
              ),

              // Content based on tab
              if (_selectedTab == 0)
                _buildInvoicesContent(casesState)
              else
                _buildNursingHoursContent(casesState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, CasesState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'التقارير والفواتير',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'معاينة الفواتير وتقارير أداء الطاقم الطبي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),

        // Toolbar: Refresh, Calendar, Month
        Row(
          children: [
            _iconButton(Icons.refresh_rounded, () => _loadData()),
            const SizedBox(width: 12),
            _iconButton(
              Icons.calendar_today_rounded,
              () async {
                final s = state is CasesLoaded ? state.customStartDate : null;
                final e = state is CasesLoaded ? state.customEndDate : null;
                final picked =
                    await CustomDateRangeDialog.show(context, start: s, end: e);
                if (picked != null && context.mounted) {
                  context.read<CasesCubit>().loadCases(
                        timeFilter: TimeFilter.custom,
                        customStartDate: picked.start,
                        customEndDate: picked.end,
                      );
                }
              },
              active:
                  state is CasesLoaded && state.timeFilter == TimeFilter.custom,
            ),
            const SizedBox(width: 12),
            _buildMonthSelector(),
          ],
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap, {bool active = false}) {
    return Container(
      decoration: BoxDecoration(
        color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppColors.primary
              : AppColors.border.withValues(alpha: 0.5),
          width: active ? 1.5 : 1.0,
        ),
      ),
      child: IconButton(
        icon: Icon(icon,
            color: active ? AppColors.primary : AppColors.textSecondary,
            size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMonthSelector() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedMonth,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          helpText: 'اختر الشهر والسنة',
        );
        if (picked != null && mounted) {
          setState(() => _selectedMonth = picked);
          _loadData();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              DateFormat('MMMM yyyy', 'ar').format(_selectedMonth),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              index: 1,
              label: 'ساعات عمل التمريض',
              icon: Icons.history_rounded,
            ),
          ),
          Expanded(
            child: _tabButton(
              index: 0,
              label: 'فواتير الحالات',
              icon: Icons.receipt_long_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(
      {required int index, required String label, required IconData icon}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D3B66) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, CasesState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          AppSearchBar(
            hintText: _selectedTab == 0
                ? 'البحث في الفواتير (اسم، هاتف)...'
                : 'البحث باسم الممرض...',
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          if (state is CasesLoaded) ...[
            const SizedBox(height: 16),
            _buildTimeFilters(context, state),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoicesContent(CasesState state) {
    if (state is CasesLoading) {
      return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()));
    }
    if (state is CasesLoaded) {
      final filtered = state.filteredCases.where((c) {
        if (_searchQuery.isEmpty) return true;
        final q = _searchQuery.toLowerCase();
        return c.patientName.toLowerCase().contains(q) ||
            c.patientPhone.contains(q);
      }).toList();

      if (filtered.isEmpty) {
        return SliverFillRemaining(
          child: EmptyStateWidget(
            icon: Icons.receipt_long_rounded,
            title: _searchQuery.isEmpty ? 'لا توجد فواتير' : 'لا توجد نتائج بحث',
            subtitle: 'جرب تغيير فلاتر البحث أو الفترة الزمنية',
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final caseData = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InvoiceCard(
                  caseData: caseData,
                  onView: () => showDialog(
                    context: context,
                    builder: (_) => InvoicePreviewDialog(caseData: caseData),
                  ),
                  onPrint: () =>
                      ReportService.instance.generateCaseInvoice(caseData),
                ),
              );
            },
            childCount: filtered.length,
          ),
        ),
      );
    }
    return SliverFillRemaining(child: Container());
  }

  Widget _buildNursingHoursContent(CasesState casesState) {
    // If a specific time filter is active (Today, Yesterday, Custom, etc.)
    // We derive the nursing report from the cases state directly.
    if (casesState is CasesLoaded && casesState.timeFilter != TimeFilter.all) {
      return _buildNursingSummaryFromCases(casesState);
    }

    // Otherwise (Monthly/All), we use the Payroll Cubit data
    return BlocBuilder<PayrollCubit, PayrollState>(
      builder: (context, state) {
        if (state is PayrollLoading) {
          return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()));
        }
        if (state is PayrollLoaded) {
          final items = state.payrolls.where((i) {
            if (_searchQuery.isEmpty) return true;
            return i.userName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
          }).toList();

          if (items.isEmpty) {
            return const SliverFillRemaining(
              child: EmptyStateWidget(
                icon: Icons.person_search_rounded,
                title: 'لا توجد سجلات تمريض',
                subtitle: 'لم يتم العثور على ممرضين لهذا الشهر',
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final payroll = items[index];
                  return _buildNurseReportCard(
                    name: payroll.userName,
                    hours: payroll.totalHours,
                    salary: payroll.netSalary,
                    casesCount: payroll.totalDays, // Or actual case count if available
                  );
                },
                childCount: items.length,
              ),
            ),
          );
        }
        return SliverFillRemaining(child: Container());
      },
    );
  }

  Widget _buildNursingSummaryFromCases(CasesLoaded state) {
    // Group cases by nurse
    final Map<String, List<dynamic>> grouped = {};
    for (var c in state.filteredCases) {
      if (!grouped.containsKey(c.nurseName)) {
        grouped[c.nurseName] = [];
      }
      grouped[c.nurseName]!.add(c);
    }

    final nurses = grouped.keys.where((name) {
      if (_searchQuery.isEmpty) return true;
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (nurses.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyStateWidget(
          icon: Icons.person_search_rounded,
          title: 'لا توجد نتائج بحث للتمريض',
          subtitle: 'جرب تغيير فلاتر التاريخ أو الاسم',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final name = nurses[index];
            final nurseCases = grouped[name]!;
            final totalCases = nurseCases.length;
            // Estimated hours or simple count
            return _buildNurseReportCard(
              name: name,
              hours: totalCases * 0.5, // Mock estimate: 30 mins per case
              salary: nurseCases.fold(0.0, (sum, c) => sum + (c.totalPrice * 0.1)), // Mock 10% commission
              casesCount: totalCases,
              isDerived: true,
            );
          },
          childCount: nurses.length,
        ),
      ),
    );
  }

  Widget _buildNurseReportCard({
    required String name,
    required double hours,
    required double salary,
    required int casesCount,
    bool isDerived = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 20,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              _infoChip(Icons.receipt_long_rounded, '$casesCount حالة'),
              const SizedBox(width: 12),
              _infoChip(Icons.timer_rounded, '${hours.toStringAsFixed(1)} ساعة'),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${salary.toStringAsFixed(0)} ج.م',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.success,
              ),
            ),
            const Text(
              'صافي المستحق',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilters(BuildContext context, CasesLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _timeTab(context, state, 'اليوم', TimeFilter.today),
          const SizedBox(width: 8),
          _timeTab(context, state, 'أمس', TimeFilter.yesterday),
          const SizedBox(width: 8),
          _timeTab(context, state, 'آخر 7 أيام', TimeFilter.last7Days),
          const SizedBox(width: 8),
          _timeTab(context, state, 'مخصص', TimeFilter.custom),
          const SizedBox(width: 8),
          _timeTab(context, state, 'الكل', TimeFilter.all),
        ],
      ),
    );
  }

  Widget _timeTab(
      BuildContext context, CasesLoaded state, String label, TimeFilter filter) {
    final isSelected = state.timeFilter == filter;
    return InkWell(
      onTap: () async {
        if (filter == TimeFilter.custom) {
          final picked = await CustomDateRangeDialog.show(context,
              start: state.customStartDate, end: state.customEndDate);
          if (picked != null && context.mounted) {
            context.read<CasesCubit>().loadCases(
                  timeFilter: TimeFilter.custom,
                  customStartDate: picked.start,
                  customEndDate: picked.end,
                );
          }
        } else {
          context.read<CasesCubit>().loadCases(timeFilter: filter);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
