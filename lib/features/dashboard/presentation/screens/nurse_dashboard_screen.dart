import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/dialogs/personal_qr_dialog.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../auth/logic/cubit/auth_cubit.dart';
import '../../../cases/data/models/case_model.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../auth/data/models/user_model.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _nurseData = {
    'todayCasesCount': 0,
    'monthHours': 0.0,
    'attendance': null,
    'todayCases': <CaseModel>[],
  };

  @override
  void initState() {
    super.initState();
    _loadNurseData();
  }

  Future<void> _loadNurseData() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthCubit>().currentUser;
    if (user != null) {
      final data = await FirebaseService.instance.getNurseDashboardStats(user.id);
      if (mounted) {
        setState(() {
          _nurseData = data;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final user = context.read<AuthCubit>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNurseData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(user),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildStaffStats(),
                    const SizedBox(height: 24),
                    _buildAttendanceStatus(),
                    const SizedBox(height: 24),
                    _buildTodaySchedule(),
                    const SizedBox(height: 100), // Space for bottom
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'حالة جديدة',
            icon: Icons.add_moderator_rounded,
            color: AppColors.secondary,
            onTap: () {
              // Usually handled by MainLayout switching index or by pushing screen
              // For simplicity, we can just show the cases screen logic
              // In this app, we might need a way to trigger MainLayout index change
              // But a common pattern is to just show the dialog for new case
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _actionButton(
            label: 'تسجيل حضور',
            icon: Icons.qr_code_scanner_rounded,
            color: AppColors.info,
            onTap: () {
              final user = context.read<AuthCubit>().currentUser;
              if (user != null) {
                PersonalQrDialog.show(context, user);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'صباح الخير' : 'مساء الخير';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting ${user?.name ?? ""} 👋',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'لوحة التحكم',
              style: AppTypography.pageTitle.copyWith(
                fontSize: ResponsiveHelper.getTitleFontSize(context),
              ),
            ),
          ],
        ),
        _buildDateChip(),
      ],
    );
  }

  Widget _buildDateChip() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            DateFormat('yyyy/MM/dd').format(now),
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffStats() {
    final hours = _nurseData['monthHours'] as double;
    final casesCount = _nurseData['todayCasesCount'] as int;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'حالات اليوم',
            value: '$casesCount',
            icon: Icons.assignment_ind_rounded,
            color: AppColors.primary,
            subtitle: 'حالات مكلف بها',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'ساعات العمل',
            value: '${hours.toStringAsFixed(1)} h',
            icon: Icons.timer_rounded,
            color: AppColors.success,
            subtitle: 'هذا الشهر',
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStatus() {
    final AttendanceModel? attendance = _nurseData['attendance'];
    final isCheckedIn = attendance != null;
    final isCheckedOut = attendance?.isCheckedOut ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCheckedIn && !isCheckedOut
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
              : [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCheckedIn && !isCheckedOut ? AppColors.success : AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCheckedOut 
                    ? Icons.done_all_rounded 
                    : (isCheckedIn ? Icons.timer_rounded : Icons.timer_outlined),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حالة الحضور اليوم',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      isCheckedOut 
                        ? 'انتهت فترة العمل' 
                        : (isCheckedIn ? 'أنت قيد العمل حالياً' : 'لم يتم تسجيل الحضور بعد'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isCheckedIn) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.white24, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _attendanceInfo('الحضور', attendance!.checkInTime),
                if (isCheckedOut)
                  _attendanceInfo('الانصراف', attendance.checkOutTime!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _attendanceInfo(String label, DateTime time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 11)),
        Text(
          DateFormat('hh:mm a', 'ar').format(time),
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTodaySchedule() {
    final List<CaseModel> cases = List<CaseModel>.from(_nurseData['todayCases'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'جدول حالات اليوم',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
            ),
            TextButton(
              onPressed: () {
                // Navigate to Cases screen with personal filter?
              },
              child: const Text('عرض الكل', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (cases.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.event_available_rounded, size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text(
                  'لا يوجد حالات مسجلة لك اليوم',
                  style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = cases[index];
              return _buildCaseStep(c);
            },
          ),
      ],
    );
  }

  Widget _buildCaseStep(CaseModel c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.patientName,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  c.patientAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusChip(c.status.name),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending': 
        color = AppColors.statusPending;
        label = 'معلق';
        break;
      case 'in_progress': 
        color = AppColors.statusInProgress;
        label = 'جاري';
        break;
      case 'completed': 
        color = AppColors.statusCompleted;
        label = 'مكتمل';
        break;
      default: 
        color = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
