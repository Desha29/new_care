import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/reports/report_service.dart';
import '../../../../core/services/excel/excel_service.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/dialogs/custom_date_range_dialog.dart';
import '../../../../core/enums/case_status.dart';
import '../../../cases/presentation/cubit/cases_cubit.dart';
import '../../../cases/presentation/cubit/cases_state.dart';
import '../../../payroll/presentation/cubit/payroll_cubit.dart';
import '../../../payroll/presentation/cubit/payroll_state.dart';
import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/local_log_service.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../cases/data/models/case_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../reports/presentation/screens/report_preview_screen.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../widgets/invoice_card.dart';
import '../widgets/invoice_preview_dialog.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  bool _showFilters = false;
  String _searchQuery = '';
  int _selectedTab = 0; // 0: Invoices, 1: Nursing Hours
  DateTime _selectedMonth = DateTime.now();
  CaseType? _filterType; // null = All
  String? _filterGender; // null = All
  String? _filterNurse; // null = All
  int? _filterDay; // null = All
  int? _filterMonth; // null = All
  int? _filterYear; // null = All
  List<AttendanceModel> _attendance = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final casesCubit = context.read<CasesCubit>();
    final payrollCubit = context.read<PayrollCubit>();

    // Load payroll for the selected month
    payrollCubit.loadPayroll(
      month: _selectedMonth.month,
      year: _selectedMonth.year,
    );

    // Fetch attendance records for reports
    try {
      final attendance = await FirebaseService.instance.getMonthlyAttendanceRecords(
        _selectedMonth.year,
        _selectedMonth.month,
      );
      if (mounted) {
        setState(() => _attendance = attendance);
      }
    } catch (e) {
      LocalLogService.instance.logError('FetchAttendance', e.toString());
      if (mounted) {
        UIFeedback.showWarning(context, 'تعذر تحميل سجلات الحضور، قد تظهر التقارير ناقصة');
      }
    }

    // Filter cases by the selected month
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final nextMonth = _selectedMonth.month == 12
        ? DateTime(_selectedMonth.year + 1, 1, 1)
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    final endOfMonth = nextMonth.subtract(const Duration(milliseconds: 1));

    casesCubit.loadCases(
      timeFilter: TimeFilter.custom,
      customStartDate: startOfMonth,
      customEndDate: endOfMonth,
    );
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

  Widget _buildSearchAndFilters(BuildContext context, CasesState state) {
    return Column(
      children: [
// 1. Unified Search & Filter Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Column(
              children: [
                Row(
                  children: [
                    if (!isMobile) ...[
// User Dropdown
                      SizedBox(
                        width: 180,
                        child: _dropdownFilter<String?>(
                          label: '', // No label for row-inline
                          icon: Icons.person_search_rounded,
                          value: _filterNurse,
                          hint: 'الموظف',
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('كل الموظفين'),
                            ),
                            ...state is CasesLoaded
                                ? state.cases
                                      .map((c) => c.nurseName)
                                      .toSet()
                                      .map(
                                        (name) => DropdownMenuItem(
                                          value: name,
                                          child: Text(name),
                                        ),
                                      )
                                : [],
                          ],
                          onChanged: (v) => setState(() => _filterNurse = v),
                        ),
                      ),
                      const SizedBox(width: 12),
// Type Dropdown
                      SizedBox(
                        width: 140,
                        child: _dropdownFilter<CaseType?>(
                          label: '',
                          icon: Icons.category_rounded,
                          value: _filterType,
                          hint: 'نوع الحالة',
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('كل الأنواع'),
                            ),
                            DropdownMenuItem(
                              value: CaseType.inCenter,
                              child: Text('مركز'),
                            ),
                            DropdownMenuItem(
                              value: CaseType.homeVisit,
                              child: Text('زيارة'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _filterType = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
// Expanded Search Bar
                    Expanded(
                      child: AppSearchBar(
                        hintText: _selectedTab == 0
                            ? 'البحث في الفواتير...'
                            : 'البحث باسم الممرض...',
                        onChanged: (v) => setState(() => _searchQuery = v),
                        onFilterTap: () =>
                            setState(() => _showFilters = !_showFilters),
                      ),
                    ),
                    const SizedBox(width: 12),
// Advanced Toggle
                    _filterToggleButton(),
                  ],
                ),
                if (isMobile) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _dropdownFilter<String?>(
                          label: '',
                          icon: Icons.person_search_rounded,
                          value: _filterNurse,
                          hint: 'الموظف',
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('الكل'),
                            ),
                            ...state is CasesLoaded
                                ? state.cases
                                      .map((c) => c.nurseName)
                                      .toSet()
                                      .map(
                                        (name) => DropdownMenuItem(
                                          value: name,
                                          child: Text(name),
                                        ),
                                      )
                                : [],
                          ],
                          onChanged: (v) => setState(() => _filterNurse = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _dropdownFilter<CaseType?>(
                          label: '',
                          icon: Icons.category_rounded,
                          value: _filterType,
                          hint: 'النوع',
                          items: const [
                            DropdownMenuItem(value: null, child: Text('الكل')),
                            DropdownMenuItem(
                              value: CaseType.inCenter,
                              child: Text('مركز'),
                            ),
                            DropdownMenuItem(
                              value: CaseType.homeVisit,
                              child: Text('زيارة'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _filterType = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),

// 2. Animated Filter Hub (Appears "Behind" Search Field)
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state is CasesLoaded) ...[
// Quick Time Filters Row
                      _buildTimeFilters(context, state),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
// Location & Gender Quick Chips
                      _buildQuickAdvancedFilters(),
                    ],
                  ],
                ),
              ),
            ],
          ),
          crossFadeState: _showFilters
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _filterToggleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _showFilters = !_showFilters),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 110, // Fixed width to ensure visibility
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _showFilters ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _showFilters ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_showFilters ? AppColors.primary : Colors.black)
                    .withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showFilters
                    ? Icons.filter_list_off_rounded
                    : Icons.filter_list_rounded,
                size: 20,
                color: _showFilters ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'تصفية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _showFilters ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, CasesState state) {
    final canPop = Navigator.canPop(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Subtitle with optional back button
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canPop) ...[
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.primary,
                tooltip: 'رجوع',
              ),
              const SizedBox(width: 8),
            ],
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
          ],
        ),

// Toolbar: Refresh, Calendar, Month
        Row(
          children: [
            _iconButton(
              Icons.today_rounded,
              () => _generateDailyReport(state),
              tooltip: 'تقرير اليوم',
            ),
            const SizedBox(width: 12),
            _iconButton(Icons.refresh_rounded, () => _loadData()),
            const SizedBox(width: 12),
            _iconButton(
              Icons.calendar_today_rounded,
              () async {
                final s = state is CasesLoaded ? state.customStartDate : null;
                final e = state is CasesLoaded ? state.customEndDate : null;
                final picked = await CustomDateRangeDialog.show(
                  context,
                  start: s,
                  end: e,
                );
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

  Widget _iconButton(
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
    String? tooltip,
  }) {
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
      child: Tooltip(
        message: tooltip ?? '',
        child: IconButton(
          icon: Icon(
            icon,
            color: active ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
          onPressed: onTap,
        ),
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
            const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              "${DateFormat('MMMM', 'ar').format(_selectedMonth)} ${_selectedMonth.year}",
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          height: isMobile ? 56 : 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _tabButton(
                  index: 1,
                  label: 'ساعات عمل التمريض',
                  icon: Icons.history_rounded,
                  isMobile: isMobile,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tabButton(
                  index: 0,
                  label: 'فواتير الحالات',
                  icon: Icons.receipt_long_rounded,
                  isMobile: isMobile,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _generateDailyReport(CasesState state) {
    if (state is! CasesLoaded) return;
    
    final today = DateTime.now();
    final todayCases = state.cases
        .where(
          (c) =>
              c.caseDate.year == today.year &&
              c.caseDate.month == today.month &&
              c.caseDate.day == today.day,
        )
        .toList();

    if (todayCases.isEmpty) {
      UIFeedback.showWarning(
        context,
        'لا توجد حالات مسجلة اليوم لإصدار تقرير بها',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          title: 'تقرير عمل اليوم - ${DateFormat('yyyy/MM/dd').format(today)}',
          fileName: 'Daily_Report_${DateFormat('yyyy_MM_dd').format(today)}',
          buildReport: () => ReportService.instance.generateCasesReportBytes(
            cases: todayCases,
            title: 'تقرير العمل اليومي',
            subtitle:
                'كشف الحالات المنفذة بتاريخ: ${DateFormat('yyyy/MM/dd').format(today)}',
          ),
          onExportExcel: () async {
            final fileName = 'Daily_Report_${DateFormat('yyyy_MM_dd').format(today)}';
            final success = await ExcelService.instance.exportCasesToExcel(todayCases, fileName);
            if (success && context.mounted) {
              UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
            } else if (!success && context.mounted) {
              UIFeedback.showError(context, 'فشل تصدير ملف Excel أو تم إلغاؤه');
            }
          },
        ),
      ),
    );
  }

  Future<void> _generateWorkReport(List<dynamic> cases) async {
    final monthName = DateFormat('MMMM yyyy', 'ar').format(_selectedMonth);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          title: 'تقرير العمل - $monthName',
          fileName: 'Work_Report_${_selectedMonth.year}_${_selectedMonth.month}',
          buildReport: () => ReportService.instance.generateCasesReportBytes(
            cases: cases.cast<CaseModel>(),
            title: 'تقرير أداء العمل التفصيلي',
            subtitle: 'كشف الحالات والخدمات لشهر: $monthName',
          ),
          onExportExcel: () async {
            final fileName = 'Work_Report_${_selectedMonth.year}_${_selectedMonth.month}';
            final success = await ExcelService.instance.exportCasesToExcel(cases.cast<CaseModel>(), fileName);
            if (success && context.mounted) {
              UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
            } else if (!success && context.mounted) {
              UIFeedback.showError(context, 'فشل تصدير ملف Excel أو تم إلغاؤه');
            }
          },
        ),
      ),
    );
  }

  Future<void> _generateFullStaffReport() async {
    try {
      LoadingDialog.show(context, message: 'جاري إعداد التقرير...');

      final shifts = await FirebaseService.instance.getMonthlyShifts(
        _selectedMonth.year,
        _selectedMonth.month,
      );

      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      String generatedBy = 'مدير النظام';
      if (authState is AuthAuthenticated) generatedBy = authState.user.name;

      LoadingDialog.hide(context);

      final monthName = DateFormat('MMMM yyyy', 'ar').format(_selectedMonth);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportPreviewScreen(
              title: 'تقرير الموظفين - $monthName',
              fileName:
                  'Staff_Report_${_selectedMonth.year}_${_selectedMonth.month}',
              buildReport: () =>
                  ReportService.instance.generateMonthlyStaffReportBytes(
                    year: _selectedMonth.year,
                    month: _selectedMonth.month,
                    attendanceRecords: _attendance,
                    shifts: shifts,
                    generatedBy: generatedBy,
                  ),
              onExportExcel: () async {
                final success = await ExcelService.instance.exportAttendanceToExcel(
                  attendanceRecords: _attendance,
                  shifts: shifts,
                  year: _selectedMonth.year,
                  month: _selectedMonth.month,
                  generatedBy: generatedBy,
                );
                if (success && context.mounted) {
                  UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
                } else if (!success && context.mounted) {
                  UIFeedback.showError(context, 'فشل تصدير ملف Excel أو تم إلغاؤه');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        UIFeedback.showError(context, 'حدث خطأ أثناء إعداد التقرير: $e');
      }
    }
  }

  void _generateSingleNurseReport(String name, String userId) {
    final userAttendance = _attendance.where((a) {
      if (userId.isNotEmpty) {
        return a.userId == userId;
      }
      // Fallback to name match if userId is not provided (e.g. from derived cases)
      return a.userName.trim().toLowerCase() == name.trim().toLowerCase();
    }).toList();

    final authState = context.read<AuthCubit>().state;
    String genBy = 'مدير النظام';
    if (authState is AuthAuthenticated) {
      genBy = authState.user.name;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          title: 'تقرير الموظف - $name',
          fileName: 'Nurse_Report_${name}_${_selectedMonth.year}_${_selectedMonth.month}',
          buildReport: () => ReportService.instance.generateSingleNurseReportBytes(
            year: _selectedMonth.year,
            month: _selectedMonth.month,
            nurseName: name,
            attendanceRecords: userAttendance,
            generatedBy: genBy,
          ),
          onExportExcel: () async {
            final success = await ExcelService.instance.exportSingleNurseAttendanceToExcel(
              attendanceRecords: userAttendance,
              nurseName: name,
              year: _selectedMonth.year,
              month: _selectedMonth.month,
            );
            if (success && context.mounted) {
              UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
            } else if (!success && context.mounted) {
              UIFeedback.showError(context, 'فشل تصدير ملف Excel أو تم إلغاؤه');
            }
          },
        ),
      ),
    );
  }

  Widget _tabButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isMobile,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF0D3B66), Color(0xFF1B4E7C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D3B66).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isMobile ? 18 : 22,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isMobile ? 12 : 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesContent(CasesState state) {
    if (state is CasesLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state is CasesLoaded) {
      final filtered = state.filteredCases.where((c) {
// Search filter
        bool matchesSearch = true;
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          matchesSearch =
              c.patientName.toLowerCase().contains(q) ||
              c.patientPhone.contains(q);
        }

// Case Type filter
        bool matchesType = _filterType == null || c.caseType == _filterType;

// Gender filter
        bool matchesGender =
            _filterGender == null || c.patientGender == _filterGender;

// Nurse filter
        bool matchesNurse = _filterNurse == null || c.nurseName == _filterNurse;

// Day filter
        bool matchesDay = _filterDay == null || c.caseDate.day == _filterDay;

// Month filter (if year is not already filtering it)
        bool matchesMonth =
            _filterMonth == null || c.caseDate.month == _filterMonth;

// Year filter
        bool matchesYear =
            _filterYear == null || c.caseDate.year == _filterYear;

        return matchesSearch &&
            matchesType &&
            matchesGender &&
            matchesNurse &&
            matchesDay &&
            matchesMonth &&
            matchesYear;
      }).toList();

      if (filtered.isEmpty) {
        return SliverFillRemaining(
          child: EmptyStateWidget(
            icon: Icons.receipt_long_rounded,
            title: _searchQuery.isEmpty
                ? 'لا توجد فواتير'
                : 'لا توجد نتائج بحث',
            subtitle: 'جرب تغيير فلاتر البحث أو الفترة الزمنية',
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _generateWorkReport(filtered),
                      icon: const Icon(Icons.description_rounded, size: 18),
                      label: const Text(
                        'إنشاء تقرير عمل شهري',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
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
            }, childCount: filtered.length),
          ),
        ],
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
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is PayrollLoaded) {
          final items = state.payrolls.where((i) {
            if (_searchQuery.isEmpty) return true;
            return i.userName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
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
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _generateFullStaffReport,
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          label: const Text(
                            'تحميل تقرير PDF شامل',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildTableHeader()),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final payroll = items[index];
                    return _buildNurseReportCard(
                      userId: payroll.userId,
                      name: payroll.userName,
                      hours: payroll.totalHours,
                      salary: payroll.netSalary,
                      casesCount: payroll.totalDays,
                    );
                  }, childCount: items.length),
                ),
              ],
            ),
          );
        }
        return SliverFillRemaining(child: Container());
      },
    );
  }

  Widget _buildTableHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'الموظف',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'عدد الحالات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'إجمالي الساعات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'صافي المستحق',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
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
        delegate: SliverChildBuilderDelegate((context, index) {
          final name = nurses[index];
          final nurseCases = grouped[name]!;
          final totalCases = nurseCases.length;

          // Calculate actual hours from attendance records
          double totalHours = 0.0;
          
          // If we have a specific time filter like Today, filter attendance for that day too
          final relevantAttendance = _attendance.where((a) {
            final matchesName = a.userName == name;
            if (!matchesName) return false;
            
            if (state.timeFilter == TimeFilter.today) {
              final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
              return a.date == todayStr;
            } else if (state.timeFilter == TimeFilter.yesterday) {
              final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
              return a.date == yesterdayStr;
            }
            // For other filters, we use the month data we already fetched
            return true;
          });

          for (var a in relevantAttendance) {
            final duration = a.shiftDuration;
            if (duration != null) {
              totalHours += duration.inMinutes / 60.0;
            }
          }

          // If no attendance found but there are cases, show a minimum of 0.5h or totalCases * 0.5 if it's a mock view
          if (totalHours == 0 && totalCases > 0) {
            totalHours = totalCases * 0.5; // Fallback estimate
          }

          return _buildNurseReportCard(
            userId: '', // No ID for derived cases yet
            name: name,
            hours: totalHours,
            salary: nurseCases.fold(
              0.0,
              (sum, c) => sum + (c.totalPrice * 0.1),
            ), // Mock 10% commission
            casesCount: totalCases,
            isDerived: true,
          );
        }, childCount: nurses.length),
      ),
    );
  }

  Widget _buildNurseReportCard({
    required String userId,
    required String name,
    required double hours,
    required double salary,
    required int casesCount,
    bool isDerived = false,
  }) {
    return InkWell(
      onTap: () => _generateSingleNurseReport(name, userId),
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (!isMobile) {
          // Desktop Row View
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '$casesCount حالة',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${hours.toStringAsFixed(1)} ساعة',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${salary.toStringAsFixed(0)} ج.م',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Card View
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
                  _infoChip(
                    Icons.timer_rounded,
                    '${hours.toStringAsFixed(1)} ساعة',
                  ),
                ],
              ),
            ),
            trailing: Text(
              '${salary.toStringAsFixed(0)} ج.م',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.success,
              ),
            ),
            onTap: () {
              // Trigger the single nurse report
              // For cases derived from cases state, the userId might be empty, 
              // but for payroll items, it's available.
              _generateSingleNurseReport(name, userId);
            },
          ),
        );
      },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نطاق التقرير:',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _timeTab(
                context,
                state,
                'اليوم',
                TimeFilter.today,
                Icons.today_rounded,
              ),
              const SizedBox(width: 10),
              _timeTab(
                context,
                state,
                'أمس',
                TimeFilter.yesterday,
                Icons.history_rounded,
              ),
              const SizedBox(width: 10),
              _timeTab(
                context,
                state,
                'آخر 7 أيام',
                TimeFilter.last7Days,
                Icons.date_range_rounded,
              ),
              const SizedBox(width: 10),
              _timeTab(
                context,
                state,
                'شهري',
                TimeFilter.thisMonth,
                Icons.calendar_month_rounded,
              ),
              const SizedBox(width: 10),
              _timeTab(
                context,
                state,
                'سنوي',
                TimeFilter.thisYear,
                Icons.calendar_today_rounded,
              ),
              const SizedBox(width: 10),
              _timeTab(
                context,
                state,
                'نطاق مخصص',
                TimeFilter.custom,
                Icons.edit_calendar_rounded,
              ),
              const SizedBox(width: 10),
              _timeTab(
                context,
                state,
                'الكل',
                TimeFilter.all,
                Icons.all_inclusive_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
// 1. Date Components Row (Day, Month, Year)
        const Text(
          'تحديد تاريخ مخصص:',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _dropdownFilter<int?>(
                label: 'اليوم',
                icon: Icons.calendar_view_day_rounded,
                value: _filterDay,
                hint: 'اختر',
                items: [
                  const DropdownMenuItem(value: null, child: Text('الكل')),
                  ...List.generate(
                    31,
                    (i) => i + 1,
                  ).map((d) => DropdownMenuItem(value: d, child: Text('$d'))),
                ],
                onChanged: (v) => setState(() => _filterDay = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownFilter<int?>(
                label: 'الشهر',
                icon: Icons.calendar_month_rounded,
                value: _filterMonth,
                hint: 'اختر',
                items: [
                  const DropdownMenuItem(value: null, child: Text('الكل')),
                  ...List.generate(
                    12,
                    (i) => i + 1,
                  ).map((m) => DropdownMenuItem(value: m, child: Text('$m'))),
                ],
                onChanged: (v) => setState(() => _filterMonth = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownFilter<int?>(
                label: 'السنة',
                icon: Icons.date_range_rounded,
                value: _filterYear,
                hint: 'اختر',
                items: [
                  const DropdownMenuItem(value: null, child: Text('الكل')),
                  ...List.generate(
                    5,
                    (i) => DateTime.now().year - 2 + i,
                  ).map((y) => DropdownMenuItem(value: y, child: Text('$y'))),
                ],
                onChanged: (v) => setState(() => _filterYear = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

// 2. Gender Chips
        Row(
          children: [
            const Text(
              'الجنس:',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            _filterChip<String?>(
              label: 'ذكر',
              icon: Icons.male_rounded,
              value: 'male',
              groupValue: _filterGender,
              onSelected: (v) =>
                  setState(() => _filterGender = _filterGender == v ? null : v),
            ),
            const SizedBox(width: 10),
            _filterChip<String?>(
              label: 'أنثى',
              icon: Icons.female_rounded,
              value: 'female',
              groupValue: _filterGender,
              onSelected: (v) =>
                  setState(() => _filterGender = _filterGender == v ? null : v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dropdownFilter<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T> onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: hint != null
                  ? Text(
                      hint,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              items: items,
              onChanged: (v) => onChanged(v as T),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeTab(
    BuildContext context,
    CasesLoaded state,
    String label,
    TimeFilter filter,
    IconData icon,
  ) {
    final isSelected = state.timeFilter == filter;
    return GestureDetector(
      onTap: () async {
        if (filter == TimeFilter.custom) {
          final picked = await CustomDateRangeDialog.show(
            context,
            start: state.customStartDate,
            end: state.customEndDate,
          );
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : AppColors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip<T>({
    required String label,
    required IconData icon,
    required T value,
    required T groupValue,
    required ValueChanged<T> onSelected,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
