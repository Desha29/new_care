// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/services/pdf/report_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../reports/presentation/screens/report_preview_screen.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../widgets/attendance_header.dart';
import '../widgets/check_in_card.dart';
import '../widgets/attendance_records_list.dart';
import 'package:intl/intl.dart';

/// شاشة الحضور والانصراف - Attendance Screen
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      print("Loading attendance for user: ${authState.user.id}");
      print("User role: ${authState.user.role}");
      context.read<AttendanceCubit>().checkTodayStatus(authState.user.id);
      context.read<AttendanceCubit>().loadTodayAttendance();
      print("Attendance loaded successfully");
    }
  }

  Future<void> _generateMonthlyReport() async {
    final now = DateTime.now();
    final authState = context.read<AuthCubit>().state;
    final userName = authState is AuthAuthenticated ? authState.user.name : 'مدير النظام';
    
    LoadingDialog.show(context, message: 'جاري إعداد التقرير...');
    
    final data = await context.read<AttendanceCubit>().getMonthlyReportData(
      now.year,
      now.month,
    );
    
    if (!mounted) return;
    LoadingDialog.hide(context);
    
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات لإعداد التقرير', style: TextStyle(fontFamily: 'Cairo'))),
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
          buildReport: () => ReportService.instance.generateMonthlyStaffReportBytes(
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
    final authState = context.watch<AuthCubit>().state;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.role.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AttendanceCubit, AttendanceState>(
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AttendanceHeader(
                  onRefresh: _loadData,
                  onGenerateReport: _generateMonthlyReport,
                ),
                const SizedBox(height: 24),
                CheckInCard(state: state),
                const SizedBox(height: 24),
                if (isAdmin)
                  Expanded(child: AttendanceRecordsList(state: state)),
              ],
            ),
          );
        },
      ),
    );
  }
}
