import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../widgets/attendance_summary_cards.dart';
import '../widgets/attendance_session_panel.dart';
import '../widgets/attendance_analytics_chart.dart';
import '../widgets/attendance_table.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../reports/presentation/screens/report_preview_screen.dart';
import '../../../../core/services/pdf/report_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceCubit>().init();
  }

  Future<void> _generateMonthlyReport() async {
    final now = DateTime.now();
    final authState = context.read<AuthCubit>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.name
        : 'مدير النظام';

    LoadingDialog.show(context, message: 'جاري إعداد التقرير...');

    final data = await context.read<AttendanceCubit>().getMonthlyReportData(
      now.year,
      now.month,
    );

    if (!mounted) return;
    LoadingDialog.hide(context);

    if (data == null) {
      UIFeedback.showWarning(
        context,
        'لا توجد بيانات لإعداد التقرير لهذا الشهر',
      );
      return;
    }

    final monthName = DateFormat('MMMM yyyy', 'ar').format(now);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          title: 'تقرير الحضور - $monthName',
          fileName: 'Attendance_Report_${now.year}_${now.month}',
          buildReport: () =>
              ReportService.instance.generateMonthlyStaffReportBytes(
                attendanceRecords: data['records'],
                shifts: data['shifts'],
                year: now.year,
                month: now.month,
                generatedBy: userName,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Ultra light grey background
      body: BlocListener<AttendanceCubit, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceError) {
            UIFeedback.showError(context, state.message);
          } else if (state is AttendanceCheckedIn) {
            UIFeedback.showSuccess(
              context,
              'تم تسجيل الحضور: ${state.record.userName}',
            );
          }
        },
        child: BlocBuilder<AttendanceCubit, AttendanceState>(
          builder: (context, state) {
            if (state is AttendanceLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AttendanceLoaded) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(),
                    const SizedBox(height: 24),
                    AttendanceSummaryCards(state: state),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: AttendanceSessionPanel(state: state),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: AttendanceAnalyticsChart(
                            stats: state.stats,
                            isLoading: state.isLoadingStats,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'سجلات حضور اليوم',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AttendanceTable(state: state),
                  ],
                ),
              );
            }

            return const Center(child: Text('جاري تحميل البيانات...'));
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لوحة التحكم بالحضور',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'إدارة جلسات الحضور ومراقبة الموظفين في الوقت الفعلي',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderButton(
              icon: Icons.refresh,
              label: 'تحديث البيانات',
              onPressed: () => context.read<AttendanceCubit>().init(),
              isOutlined: true,
            ),
            const SizedBox(width: 12),
            _buildHeaderButton(
              icon: Icons.file_download_outlined,
              label: 'تصدير تقرير الشهر',
              onPressed: _generateMonthlyReport,
              isOutlined: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isOutlined,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
