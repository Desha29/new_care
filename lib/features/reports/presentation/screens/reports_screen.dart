import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../auth/logic/cubit/auth_cubit.dart';
import '../../../cases/data/models/case_model.dart';
// For _buildStatusChip if needed or similar
import '../../../invoice/presentation/screens/invoice_preview_screen.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../auth/logic/cubit/auth_state.dart';
import '../../../attendance/data/models/attendance_model.dart';
import 'nurse_report_preview_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final cases = await FirebaseService.instance.getAllCases();
      final attendance = await FirebaseService.instance
          .getMonthlyAttendanceRecords(_selectedDate.year, _selectedDate.month);

      setState(() {
        _cases = cases..sort((a, b) => b.caseDate.compareTo(a.caseDate));
        _attendance = attendance;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e')));
      }
      setState(() => _isLoading = false);
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
    return Row(
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
        const Spacer(),
        _buildDatePicker(),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
        ),
      ],
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'فواتير الحالات'),
          Tab(text: 'ساعات عمل التمريض'),
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

    if (filteredCases.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long_rounded,
        title: 'لا توجد فواتير لهذا الشهر',
        subtitle: 'سيتم عرض فواتير الحالات المسجلة هنا',
      );
    }

    return ListView.builder(
      itemCount: filteredCases.length,
      itemBuilder: (context, index) {
        final c = filteredCases[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.receipt_rounded,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              c.patientName,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${DateFormat('yyyy/MM/dd').format(c.caseDate)} • ${c.caseType.label} • ${c.nurseName}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(c.totalPrice - c.discount).toStringAsFixed(0)} E.P',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(
                    Icons.visibility_rounded,
                    color: AppColors.info,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoicePreviewScreen(caseData: c),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text(
                'تحميل تقرير PDF شامل',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              itemCount: staffList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = staffList[index];
                final name = names[entry.key] ?? 'مجهول';
                final hours = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      final userAttendance = _attendance
                          .where((a) => a.userId == entry.key)
                          .toList();

                      final authState = context.read<AuthCubit>().state;
                      String genBy = 'مدير النظام';
                      if (authState is AuthAuthenticated)
                        genBy = authState.user.name;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NurseReportPreviewScreen(
                            nurseName: name,
                            year: _selectedDate.year,
                            month: _selectedDate.month,
                            attendanceRecords: userAttendance,
                            generatedBy: genBy,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
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
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'انقر لمعاينة تقرير الحضور التفصيلي',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: AppColors.primary,
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
                );
              },
            ),
          ),
        ),
      ],
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

      final authState = context.read<AuthCubit>().state;
      String generatedBy = 'مدير النظام';
      if (authState is AuthAuthenticated) generatedBy = authState.user.name;

      if (mounted) LoadingDialog.hide(context);

      await ReportService.instance.generateMonthlyStaffReport(
        year: _selectedDate.year,
        month: _selectedDate.month,
        attendanceRecords: _attendance,
        shifts: shifts,
        generatedBy: generatedBy,
      );
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
