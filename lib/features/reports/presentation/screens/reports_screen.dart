import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_care/core/constants/app_colors.dart';
import 'package:new_care/core/constants/app_typography.dart';
import 'package:new_care/core/utils/responsive_helper.dart';
import 'package:new_care/core/widgets/empty_state_widget.dart';
import 'package:new_care/core/widgets/dialogs/loading_dialog.dart';
import 'package:new_care/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:new_care/features/auth/presentation/cubit/auth_state.dart';
import 'package:new_care/features/cases/data/models/case_model.dart';
import 'package:new_care/features/invoice/presentation/screens/invoice_preview_screen.dart';
import 'package:new_care/core/services/local/sqlite_service.dart';
import 'package:new_care/core/services/firebase/firebase_service.dart';
import 'package:new_care/core/services/pdf/report_service.dart';
import 'package:new_care/core/services/notifications/case_change_notifier.dart';
import 'package:new_care/features/attendance/data/models/attendance_model.dart';
import 'report_preview_screen.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<CaseModel> _cases = [];
  List<AttendanceModel> _attendance = [];
  DateTime _selectedDate = DateTime.now();
  StreamSubscription? _caseChangeSub;

  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();

    // Listen for case changes (add/update/delete) to auto-refresh
    _caseChangeSub = CaseChangeNotifier().onCaseChanged.listen((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _caseChangeSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authState = context.read<AuthCubit>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      final isAdmin = user?.role.isAdmin ?? false;

      // Read cases from local SQLite (offline-first)
      final localCases = await SqliteService.instance.getAllCases();
      var cases = localCases
          .map((m) => CaseModel.fromMap(m, m['id'] as String))
          .toList();

      // Filter cases for nurses
      if (!isAdmin && user != null) {
        cases = cases.where((c) => c.nurseId == user.id).toList();
      }

      // Attendance still from Firestore (no local monthly query)
      List<AttendanceModel> attendance = [];
      try {
        attendance = await FirebaseService.instance
            .getMonthlyAttendanceRecords(_selectedDate.year, _selectedDate.month);
        
        // Filter attendance for nurses
        if (!isAdmin && user != null) {
          attendance = attendance.where((a) => a.userId == user.id).toList();
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _cases = cases..sort((a, b) => b.caseDate.compareTo(a.caseDate));
          _attendance = attendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTabs(),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInvoicesTab(),
                        _buildAttendanceReportTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              'التقارير والفواتير',
              style: AppTypography.pageTitle.copyWith(fontSize: titleSize),
            ),
            Text(
              'معاينة الفواتير وتقارير أداء الطاقم الطبي',
              style: AppTypography.pageSubtitle,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDatePicker(),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _generateDailyReport,
              icon: const Icon(Icons.today_rounded, color: AppColors.secondary),
              tooltip: 'تقرير اليوم',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  void _generateDailyReport() {
    final today = DateTime.now();
    final todayCases = _cases
        .where(
          (c) =>
              c.caseDate.year == today.year &&
              c.caseDate.month == today.month &&
              c.caseDate.day == today.day,
        )
        .toList();

    if (todayCases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد حالات مسجلة اليوم لإصدار تقرير بها'),
        ),
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
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2023),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('MMMM yyyy', 'ar').format(_selectedDate),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            height: 45,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 18),
                SizedBox(width: 8),
                Text('فواتير الحالات'),
              ],
            ),
          ),
          Tab(
            height: 45,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 18),
                SizedBox(width: 8),
                Text('ساعات عمل التمريض'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    final filteredCases = _cases
        .where(
          (c) =>
              c.caseDate.year == _selectedDate.year &&
              c.caseDate.month == _selectedDate.month,
        )
        .toList();

    return Column(
      children: [
        if (filteredCases.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _generateWorkReport(filteredCases),
                  icon: const Icon(Icons.description_rounded, size: 18),
                  label: const Text(
                    'إنشاء تقرير عمل شهري',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: filteredCases.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.receipt_long_rounded,
                  title: 'لا توجد فواتير لهذا الشهر',
                  subtitle: 'سيتم عرض فواتير الحالات المسجلة هنا',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filteredCases.length,
                  itemBuilder: (context, index) {
                    final c = filteredCases[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                color: AppColors.primary,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        child: const Icon(
                                          Icons.receipt_rounded,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              c.patientName,
                                              style: const TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${DateFormat('yyyy/MM/dd').format(c.caseDate)} • ${c.caseType.label} • ${c.nurseName}',
                                              style: const TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${(c.totalPrice - c.discount).toStringAsFixed(0)} E.P',
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.info.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.visibility_rounded,
                                                color: AppColors.info,
                                                size: 20,
                                              ),
                                              onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      InvoicePreviewScreen(caseData: c),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAttendanceReportTab() {
    if (_attendance.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history_rounded,
        title: 'لا توجد سجلات حضور',
        subtitle: 'اختر شهراً آخر أو تأكد من وجود سجلات حضور للموظفين',
      );
    }

    // تجميع الساعات حسب الممرض
    final Map<String, double> hourlyWork = {};
    final Map<String, String> names = {};

    for (var record in _attendance) {
      names[record.userId] = record.userName;
      if (record.checkOutTime != null) {
        final hours =
            record.checkOutTime!.difference(record.checkInTime).inMinutes /
            60.0;
        hourlyWork[record.userId] = (hourlyWork[record.userId] ?? 0) + hours;
      }
    }

    final staffList = hourlyWork.entries.toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _generateFullStaffReport,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text(
                'تحميل تقرير PDF شامل',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final entry = staffList[index];
              final name = names[entry.key] ?? 'مجهول';
              final hours = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          color: AppColors.secondary,
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final userAttendance = _attendance
                                  .where((a) => a.userId == entry.key)
                                  .toList();

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
                                    fileName:
                                        'Nurse_Report_${name}_${_selectedDate.year}_${_selectedDate.month}',
                                    buildReport: () => ReportService.instance
                                        .generateSingleNurseReportBytes(
                                          year: _selectedDate.year,
                                          month: _selectedDate.month,
                                          nurseName: name,
                                          attendanceRecords: userAttendance,
                                          generatedBy: genBy,
                                        ),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.secondary.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'انقر لمعاينة تقرير الحضور التفصيلي',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${hours.toStringAsFixed(1)} ساعة',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textHint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _generateWorkReport(List<CaseModel> cases) async {
    final monthName = '${_months[_selectedDate.month - 1]} ${_selectedDate.year}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          title: 'تقرير العمل - $monthName',
          fileName: 'Work_Report_${_selectedDate.year}_${_selectedDate.month}',
          buildReport: () => ReportService.instance.generateCasesReportBytes(
            cases: cases,
            title: 'تقرير أداء العمل التفصيلي',
            subtitle: 'كشف الحالات والخدمات لشهر: $monthName',
          ),
        ),
      ),
    );
  }

  Future<void> _generateFullStaffReport() async {
    try {
      LoadingDialog.show(context, message: 'جاري إعداد التقرير...');

      // نحتاج الورديات أيضاً للتقرير الكامل
      final shifts = await FirebaseService.instance.getMonthlyShifts(
        _selectedDate.year,
        _selectedDate.month,
      );

      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      String generatedBy = 'مدير النظام';
      if (authState is AuthAuthenticated) generatedBy = authState.user.name;

      LoadingDialog.hide(context);

      final monthName = DateFormat('MMMM yyyy', 'ar').format(_selectedDate);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportPreviewScreen(
              title: 'تقرير الموظفين - $monthName',
              fileName:
                  'Staff_Report_${_selectedDate.year}_${_selectedDate.month}',
              buildReport: () =>
                  ReportService.instance.generateMonthlyStaffReportBytes(
                    year: _selectedDate.year,
                    month: _selectedDate.month,
                    attendanceRecords: _attendance,
                    shifts: shifts,
                    generatedBy: generatedBy,
                  ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }
}

