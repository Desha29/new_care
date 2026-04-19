import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/dialogs/personal_qr_dialog.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../auth/logic/cubit/auth_cubit.dart';
import '../../../auth/logic/cubit/auth_state.dart';
import '../../logic/cubit/attendance_cubit.dart';
import '../../logic/cubit/attendance_state.dart';
import '../../data/models/attendance_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/services/firebase_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// شاشة الحضور والانصراف - Attendance Screen
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();

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
      LoadingDialog.show(context, message: 'جاري إعداد التقرير...');

      final attendanceRecords = await FirebaseService.instance
          .getMonthlyAttendanceRecords(now.year, now.month);
      final shifts = await FirebaseService.instance.getMonthlyShifts(
        now.year,
        now.month,
      );

      final authState = context.read<AuthCubit>().state;
      String generatedBy = 'مدير النظام';
      if (authState is AuthAuthenticated) generatedBy = authState.user.name;

      if (context.mounted) LoadingDialog.hide(context);

      await ReportService.instance.generateMonthlyStaffReport(
        year: now.year,
        month: now.month,
        attendanceRecords: attendanceRecords,
        shifts: shifts,
        generatedBy: generatedBy,
      );
    } catch (e) {
      if (context.mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
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
    final authState = context.read<AuthCubit>().state;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.role.isAdmin;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الحضور والانصراف',
              style: AppTypography.pageTitle.copyWith(fontSize: titleSize),
            ),
            Text(
              isAdmin
                  ? 'مراقبة حضور الطاقم وتسجيل QR'
                  : 'تسجيل حضورك الشخصي للمناوبة',
              style: AppTypography.pageSubtitle.copyWith(
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              ),
            ),
          ],
        ),
        const Spacer(),
        if (isAdmin) ...[
          SizedBox(
            width: 250,
            height: 45,
            child: TextField(
              controller: _scanController,
              focusNode: _scanFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'امسح الـ QR أو ادخل الكود...',
                hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onSubmitted: (value) => _processQrScan(context, value),
            ),
          ),
          const SizedBox(width: 12),
        ],
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final isAdmin =
                authState is AuthAuthenticated && authState.user.role.isAdmin;
            if (isAdmin) {
              return Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _generateMonthlyReport,
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: Text(
                      ResponsiveHelper.isMobile(context)
                          ? 'تقرير'
                          : 'تقرير شهري',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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

  void _processQrScan(BuildContext context, String rawValue) async {
    if (rawValue.isEmpty) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    // توقع التنسيق: UID:Name أو مجرد UID
    final parts = rawValue.split(':');
    final targetUid = parts.isNotEmpty ? parts[0].trim() : '';
    String targetName = parts.length > 1 ? parts[1].trim() : 'ممرض';

    if (targetUid.length < 5) return; // كود غير صالح

    // إذا لم يتوفر الاسم في الـ QR، نحاول إيجاده من قائمة المستخدمين
    if (targetName == 'ممرض') {
      try {
        final user = await FirebaseService.instance.getUser(targetUid);
        if (user != null) targetName = user.name;
      } catch (_) {}
    }

    if (mounted) {
      context.read<AttendanceCubit>().checkInByUserId(
        targetUserId: targetUid,
        targetUserName: targetName,
        adminUserId: authState.user.id,
        adminUserName: authState.user.name,
      );
      _scanController.clear();
      _scanFocusNode.requestFocus(); // العودة للتركيز للمسح التالي
    }
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

    final isAdmin = user.role.isAdmin;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: isCheckedIn || isAdmin
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (isCheckedIn || isAdmin ? AppColors.success : AppColors.primary)
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
                const SizedBox(height: 12),
                if (isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'أنت معفى من تسجيل الحضور بصفتك مدير',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (isCheckedIn && todayRecord != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
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
          if (!isAdmin)
            Column(
              children: [
                if (!isCheckedIn)
                  _buildNurseQrTrigger(context, user)
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
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
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

  Widget _buildNurseQrTrigger(BuildContext context, UserModel user) {
    return InkWell(
      onTap: () => PersonalQrDialog.show(context, user),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 40),
            SizedBox(height: 8),
            Text(
              'عرض الـ QR',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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

  void _handleCheckOut(BuildContext context, String userId, String userName) {
    context.read<AttendanceCubit>().checkOut(
      userId: userId,
      userName: userName,
    );
  }

  Widget _buildTodayRecords(BuildContext context, AttendanceState state) {
    final authState = context.read<AuthCubit>().state;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.role.isAdmin;

    if (!isAdmin) return const SizedBox.shrink();

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
                const Icon(
                  Icons.people_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                _hc('إجراء', 1),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: state is AttendanceLoading
                ? const Center(child: CircularProgressIndicator())
                : records.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.fingerprint_rounded,
                    title: 'لا توجد سجلات حضور اليوم',
                    subtitle: 'سيتم عرض سجلات الحضور هنا عند تسجيلها',
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
    child: Text(t, style: AppTypography.tableHeader.copyWith(fontSize: 12)),
  );

  Widget _recordRow(AttendanceModel record, int i) {
    final checkInTime = DateFormat('hh:mm a', 'ar').format(record.checkInTime);
    final checkOutTime = record.checkOutTime != null
        ? DateFormat('hh:mm a', 'ar').format(record.checkOutTime!)
        : '---';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven
          ? Colors.transparent
          : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: AppColors.secondary,
                  ),
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
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.success,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              checkOutTime,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: record.isCheckedOut
                    ? AppColors.error
                    : AppColors.textHint,
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
                  color: record.isCheckedIn
                      ? AppColors.success
                      : AppColors.textHint,
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
          Expanded(
            flex: 1,
            child: (record.isCheckedIn && !record.isCheckedOut)
                ? IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    onPressed: () => _handleCheckOut(
                      context,
                      record.userId,
                      record.userName,
                    ),
                    tooltip: 'تسجيل انصراف يدوي',
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
