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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_care/features/cases/data/models/case_model.dart';
import 'package:new_care/features/cases/domain/repositories/cases_repository.dart';
import 'package:new_care/core/services/firebase/firebase_service.dart';
import 'package:new_care/core/services/pdf/report_service.dart';
import 'package:new_care/core/services/excel/excel_service.dart';
import 'package:new_care/core/services/notifications/case_change_notifier.dart';
import 'package:new_care/features/attendance/data/models/attendance_model.dart';
import 'package:new_care/core/utils/ui_feedback.dart';
import 'package:new_care/core/widgets/app_search_bar.dart';
import 'package:new_care/features/invoice/presentation/widgets/invoice_card.dart';
import '../../../invoice/presentation/widgets/invoice_preview_dialog.dart';
import 'package:new_care/features/procedures/domain/repositories/procedures_repository.dart';
import 'report_preview_screen.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _invoiceScrollController = ScrollController();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  List<CaseModel> _cases = [];
  List<AttendanceModel> _attendance = [];
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  StreamSubscription? _caseChangeSub;

  static const _months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _invoiceScrollController.addListener(_onInvoiceScroll);
    _loadData();

    // Listen for case changes (add/update/delete) to auto-refresh
    _caseChangeSub = CaseChangeNotifier().onCaseChanged.listen((_) {
      _loadData();
    });
  }

  void _onInvoiceScroll() {
    if (_invoiceScrollController.position.pixels >=
        _invoiceScrollController.position.maxScrollExtent * 0.9) {
      _loadMoreInvoices();
    }
  }

  @override
  void dispose() {
    _caseChangeSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _cases = [];
      _lastDocument = null;
      _hasMore = true;
    });
    try {
      final authState = context.read<AuthCubit>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      final isAdmin = user?.role.isAdmin ?? false;
      final nurseId = isAdmin ? null : user?.id;

      final repo = GetIt.I<ICasesRepository>();

      // Calculate start and end of selected month
      final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endOfMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        0,
        23,
        59,
        59,
      );

      final result = await repo.getCasesPaginated(
        nurseId: nurseId,
        startDate: startOfMonth,
        endDate: endOfMonth,
        limit: 20,
      );

      // Attendance
      List<AttendanceModel> attendance = [];
      try {
        attendance = await FirebaseService.instance.getMonthlyAttendanceRecords(
          _selectedDate.year,
          _selectedDate.month,
        );

        if (!isAdmin && user != null) {
          attendance = attendance.where((a) => a.userId == user.id).toList();
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _cases = result.items;
          _lastDocument = result.lastDocument;
          _hasMore = result.hasMore;
          _attendance = attendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        UIFeedback.showError(context, 'خطأ في تحميل البيانات: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreInvoices() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);
    try {
      final authState = context.read<AuthCubit>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      final isAdmin = user?.role.isAdmin ?? false;
      final nurseId = isAdmin ? null : user?.id;

      final repo = GetIt.I<ICasesRepository>();

      final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endOfMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        0,
        23,
        59,
        59,
      );

      final result = await repo.getCasesPaginated(
        nurseId: nurseId,
        startDate: startOfMonth,
        endDate: endOfMonth,
        startAfter: _lastDocument,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _cases.addAll(result.items);
          _lastDocument = result.lastDocument;
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
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
    final canPop = Navigator.canPop(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
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
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDatePicker(),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'today') {
                  final now = DateTime.now();
                  _generateReportForRange(
                    DateTime(now.year, now.month, now.day),
                    DateTime(now.year, now.month, now.day, 23, 59, 59),
                    'تقرير اليوم',
                    'Daily',
                  );
                } else if (value == 'yesterday') {
                  final yesterday = DateTime.now().subtract(
                    const Duration(days: 1),
                  );
                  _generateReportForRange(
                    DateTime(yesterday.year, yesterday.month, yesterday.day),
                    DateTime(
                      yesterday.year,
                      yesterday.month,
                      yesterday.day,
                      23,
                      59,
                      59,
                    ),
                    'تقرير أمس',
                    'Yesterday',
                  );
                } else if (value == 'custom') {
                  _showCustomRangePicker();
                } else if (value == 'procedures') {
                  _generateProceduresReport();
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.secondary,
                ),
              ),
              tooltip: 'إصدار تقرير',
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'today',
                  child: Row(
                    children: [
                      Icon(
                        Icons.today_rounded,
                        size: 20,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 10),
                      Text('تقرير اليوم'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'yesterday',
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        size: 20,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 10),
                      Text('تقرير أمس'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'custom',
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 10),
                      Text('فترة مخصصة...'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'procedures',
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_services_rounded,
                        size: 20,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 10),
                      Text('تقرير الإجراءات والأسعار'),
                    ],
                  ),
                ),
              ],
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

  Future<void> _generateReportForRange(
    DateTime start,
    DateTime end,
    String label,
    String prefix,
  ) async {
    LoadingDialog.show(context);
    try {
      final authState = context.read<AuthCubit>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      final isAdmin = user?.role.isAdmin ?? false;
      final nurseId = isAdmin ? null : user?.id;

      final repo = GetIt.I<ICasesRepository>();
      final result = await repo.getAllCases(nurseId: nurseId);

      final filteredCases = result.where((c) {
        return c.caseDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            c.caseDate.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();

      if (mounted) LoadingDialog.hide(context);

      if (filteredCases.isEmpty) {
        if (mounted)
          UIFeedback.showWarning(context, 'لا توجد حالات في الفترة المختارة');
        return;
      }

      final dateStr = DateFormat('yyyy/MM/dd').format(start);
      final subtitle =
          start.day == end.day &&
              start.month == end.month &&
              start.year == end.year
          ? 'كشف الحالات بتاريخ: $dateStr'
          : 'كشف الحالات من: ${DateFormat('MM/dd').format(start)} إلى: ${DateFormat('MM/dd').format(end)}';

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportPreviewScreen(
              title: '$label - ${DateFormat('yyyy-MM-dd').format(start)}',
              fileName:
                  '${prefix}_Report_${DateFormat('yyyy_MM_dd').format(start)}',
              buildReport: () =>
                  ReportService.instance.generateCasesReportBytes(
                    cases: filteredCases,
                    title: label,
                    subtitle: subtitle,
                  ),
              onExportExcel: () async {
                final success = await ExcelService.instance.exportCasesToExcel(
                  filteredCases,
                  '${prefix}_Report_${DateFormat('yyyy_MM_dd').format(start)}',
                );
                if (success && context.mounted) {
                  UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        UIFeedback.showError(context, 'خطأ أثناء إصدار التقرير: $e');
      }
    }
  }

  Future<void> _showCustomRangePicker() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      _generateReportForRange(
        range.start,
        DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
        'تقرير فترة مخصصة',
        'Custom',
      );
    }
  }

  Future<void> _generateProceduresReport() async {
    LoadingDialog.show(context);
    try {
      final repo = GetIt.I<IProceduresRepository>();
      final procedures = await repo.getAllProcedures();

      if (mounted) LoadingDialog.hide(context);

      if (procedures.isEmpty) {
        if (mounted)
          UIFeedback.showWarning(context, 'لا توجد إجراءات مسجلة حالياً');
        return;
      }

      final authState = context.read<AuthCubit>().state;
      final userName = authState is AuthAuthenticated
          ? authState.user.name
          : 'مسؤول';

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportPreviewScreen(
              title: 'تقرير قائمة الإجراءات والأسعار',
              fileName:
                  'Procedures_List_${DateFormat('yyyy_MM_dd').format(DateTime.now())}',
              buildReport: () =>
                  ReportService.instance.generateProceduresReportBytes(
                    procedures: procedures,
                    generatedBy: userName,
                  ),
              onExportExcel: () async {
                final success = await ExcelService.instance.exportProceduresToExcel(
                  procedures,
                  'Procedures_List_${DateFormat('yyyy_MM_dd').format(DateTime.now())}',
                );
                if (success && context.mounted) {
                  UIFeedback.showSuccess(
                    context,
                    'تم تصدير كشف الإجراءات بنجاح',
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        UIFeedback.showError(context, 'خطأ أثناء إصدار تقرير الإجراءات: $e');
      }
    }
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
              color: AppColors.primary.withValues(alpha: 0.3),
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
    final filtered = _cases.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.patientName.toLowerCase().contains(q) ||
          c.patientPhone.contains(q) ||
          c.nurseName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppSearchBar(
            hintText: 'البحث في الفواتير (اسم، هاتف، ممرض)...',
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        if (filtered.isNotEmpty)
          Padding(
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
        Expanded(
          child: filtered.isEmpty && !_isLoading
              ? EmptyStateWidget(
                  icon: Icons.receipt_long_rounded,
                  title: _searchQuery.isEmpty
                      ? 'لا توجد فواتير لهذا الشهر'
                      : 'لا توجد نتائج بحث',
                  subtitle: _searchQuery.isEmpty
                      ? 'سيتم عرض فواتير الحالات المسجلة هنا'
                      : 'جرب البحث بكلمات أخرى',
                )
              : ListView.builder(
                  controller: _invoiceScrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < filtered.length) {
                      final c = filtered[index];
                      return InvoiceCard(
                        caseData: c,
                        onView: () => showDialog(
                          context: context,
                          builder: (_) => InvoicePreviewDialog(caseData: c),
                        ),
                        onPrint: () =>
                            ReportService.instance.generateCaseInvoice(c),
                      );
                    } else {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
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
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
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
                        Container(width: 6, color: AppColors.secondary),
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
                                    onExportExcel: () async {
                                      final success = await ExcelService
                                          .instance
                                          .exportSingleNurseAttendanceToExcel(
                                            attendanceRecords: userAttendance,
                                            nurseName: name,
                                            year: _selectedDate.year,
                                            month: _selectedDate.month,
                                          );
                                      if (success && context.mounted) {
                                        UIFeedback.showSuccess(
                                          context,
                                          'تم تصدير ملف Excel بنجاح',
                                        );
                                      } else if (!success && context.mounted) {
                                        UIFeedback.showError(
                                          context,
                                          'فشل تصدير ملف Excel أو تم إلغاؤه',
                                        );
                                      }
                                    },
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
                                    backgroundColor: AppColors.secondary
                                        .withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                      color: AppColors.success.withValues(
                                        alpha: 0.1,
                                      ),
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
    final monthName =
        '${_months[_selectedDate.month - 1]} ${_selectedDate.year}';

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
          onExportExcel: () async {
            final fileName =
                'Work_Report_${_selectedDate.year}_${_selectedDate.month}';
            final success = await ExcelService.instance.exportCasesToExcel(
              cases,
              fileName,
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

  Future<void> _generateFullStaffReport() async {
    try {
      LoadingDialog.show(context, message: 'جاري إعداد التقرير...');

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
              onExportExcel: () async {
                final success = await ExcelService.instance
                    .exportAttendanceToExcel(
                      attendanceRecords: _attendance,
                      shifts: shifts,
                      year: _selectedDate.year,
                      month: _selectedDate.month,
                      generatedBy: generatedBy,
                    );
                if (success && context.mounted) {
                  UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
                } else if (!success && context.mounted) {
                  UIFeedback.showError(
                    context,
                    'فشل تصدير ملف Excel أو تم إلغاؤه',
                  );
                }
              },
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
