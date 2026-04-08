import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/logic/cubit/auth_cubit.dart';
import '../../../auth/logic/cubit/auth_state.dart';
import '../../logic/cubit/attendance_cubit.dart';
import '../../logic/cubit/attendance_state.dart';
import '../../data/models/attendance_model.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/services/firebase_service.dart';

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
      context.read<AttendanceCubit>().checkTodayStatus(authState.user.id);
    }
  }

  Future<void> _generateMonthlyReport() async {
    final now = DateTime.now();
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final attendanceRecords = await FirebaseService.instance.getMonthlyAttendanceRecords(now.year, now.month);
      final shifts = await FirebaseService.instance.getMonthlyShifts(now.year, now.month);
      
      final authState = context.read<AuthCubit>().state;
      String generatedBy = 'مدير النظام';
      if (authState is AuthAuthenticated) generatedBy = authState.user.name;

      if (context.mounted) Navigator.pop(context); // Close loading

      await ReportService.instance.generateMonthlyStaffReport(
        year: now.year,
        month: now.month,
        attendanceRecords: attendanceRecords,
        shifts: shifts,
        generatedBy: generatedBy,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AttendanceCubit, AttendanceState>(
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildCheckInCard(context, state),
                const SizedBox(height: 24),
                Expanded(child: _buildTodayRecords(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final titleSize = ResponsiveHelper.getTitleFontSize(context);
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الحضور والانصراف',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'تسجيل الحضور والانصراف ومتابعة الموظفين',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final isAdmin = authState is AuthAuthenticated && authState.user.role.isAdmin;
            if (isAdmin) {
              return Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _generateMonthlyReport,
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: Text(ResponsiveHelper.isMobile(context) ? 'تقرير' : 'تقرير شهري', style: const TextStyle(fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildCheckInCard(BuildContext context, AttendanceState state) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final user = authState.user;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'ar').format(now);

    bool isCheckedIn = false;
    AttendanceModel? todayRecord;

    if (state is AttendanceLoaded) {
      isCheckedIn = state.isCheckedIn;
      todayRecord = state.todayRecord;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: isCheckedIn
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCheckedIn ? AppColors.success : AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، ${user.name}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                if (isCheckedIn && todayRecord != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'تسجيل الحضور: ${DateFormat('hh:mm a', 'ar').format(todayRecord.checkInTime)}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (todayRecord.isCheckedOut) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'الانصراف: ${DateFormat('hh:mm a', 'ar').format(todayRecord.checkOutTime!)} • ${todayRecord.shiftDurationText}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            children: [
              if (!isCheckedIn)
                _buildActionButton(
                  label: 'تسجيل حضور',
                  icon: Icons.fingerprint_rounded,
                  color: Colors.white,
                  textColor: AppColors.primary,
                  onTap: () => _handleCheckIn(context, user.id, user.name),
                )
              else if (todayRecord != null && !todayRecord.isCheckedOut)
                _buildActionButton(
                  label: 'تسجيل انصراف',
                  icon: Icons.logout_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  textColor: Colors.white,
                  onTap: () => _handleCheckOut(context, user.id, user.name),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'تم الانتهاء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCheckIn(BuildContext context, String userId, String userName) {
    context.read<AttendanceCubit>().checkIn(
      userId: userId,
      userName: userName,
    );
  }

  void _handleCheckOut(BuildContext context, String userId, String userName) {
    context.read<AttendanceCubit>().checkOut(
      userId: userId,
      userName: userName,
    );
  }

  Widget _buildTodayRecords(BuildContext context, AttendanceState state) {
    List<AttendanceModel> records = [];
    if (state is AttendanceLoaded) {
      records = state.records;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                const Text(
                  'سجلات حضور اليوم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${records.length} سجل',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _hc('الموظف', 3),
                _hc('وقت الحضور', 2),
                _hc('وقت الانصراف', 2),
                _hc('الحالة', 2),
                _hc('الجهاز', 2),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: state is AttendanceLoading
                ? const Center(child: CircularProgressIndicator())
                : records.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد سجلات حضور اليوم',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.textHint,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.borderLight),
                        itemBuilder: (_, i) => _recordRow(records[i], i),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _hc(String t, int f) => Expanded(
    flex: f,
    child: Text(
      t,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Widget _recordRow(AttendanceModel record, int i) {
    final checkInTime = DateFormat('hh:mm a', 'ar').format(record.checkInTime);
    final checkOutTime = record.checkOutTime != null
        ? DateFormat('hh:mm a', 'ar').format(record.checkOutTime!)
        : '---';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_rounded, size: 16, color: AppColors.secondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    record.userName,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              checkInTime,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.success),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              checkOutTime,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: record.isCheckedOut ? AppColors.error : AppColors.textHint,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: record.isCheckedIn
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.textHint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                record.status.label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: record.isCheckedIn ? AppColors.success : AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              record.deviceId.length > 15
                  ? '${record.deviceId.substring(0, 15)}...'
                  : record.deviceId,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: AppColors.textHint,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
