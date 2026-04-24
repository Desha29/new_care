import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/dialogs/personal_qr_dialog.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../cases/data/models/case_model.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../../cases/presentation/widgets/case_form_dialog.dart';
import '../../../cases/presentation/cubit/cases_cubit.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().currentUser;
    if (user != null) {
      context.read<DashboardCubit>().loadNurseDashboardData(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final user = context.read<AuthCubit>().currentUser;

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DashboardError) {
          return Scaffold(
            body: Center(child: Text('Error: ${state.message}')),
          );
        }

        if (state is DashboardLoaded) {
          final nurseData = state.stats;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  return context.read<DashboardCubit>().loadNurseDashboardData(user.id);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(user),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildStaffStats(nurseData),
                          const SizedBox(height: 24),
                          _buildAttendanceStatus(nurseData),
                          const SizedBox(height: 24),
                          _buildTodaySchedule(nurseData),
                          const SizedBox(height: 100), // Space for bottom
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildQuickActions() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 2),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isDesktop ? 1.5 : 1.3,
      children: [
        _actionButton(
          label: 'حالة جديدة',
          icon: Icons.add_moderator_rounded,
          color: AppColors.secondary,
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: context.read<CasesCubit>()),
                  BlocProvider.value(value: context.read<DashboardCubit>()),
                ],
                child: const CaseFormDialog(),
              ),
            );
          },
        ),
        _actionButton(
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
        _actionButton(
          label: 'المخزون',
          icon: Icons.inventory_2_rounded,
          color: Colors.orange,
          onTap: () {
            // Logic to switch to inventory tab if needed
          },
        ),
        _actionButton(
          label: 'التقارير',
          icon: Icons.analytics_rounded,
          color: Colors.purple,
          onTap: () {
            // Logic to switch to reports tab if needed
          },
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
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
              '$greeting ${user?.name ?? ""} 👋',
              style: const TextStyle(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('yyyy/MM/dd').format(now),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffStats(Map<String, dynamic> nurseData) {
    final hours = (nurseData['totalIncome'] ?? 0.0) as double;
    final casesCount = (nurseData['todayCases'] ?? 0) as int;
    
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 1),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isDesktop ? 1.4 : 2.5,
      children: [
        StatCard(
          title: 'حالات اليوم',
          value: '$casesCount',
          icon: Icons.assignment_ind_rounded,
          color: AppColors.primary,
          subtitle: 'حالة مكلف بها',
          onTap: () {
            // Navigate to detailed list or cases tab
          },
        ),
        StatCard(
          title: 'ساعات العمل',
          value: '${hours.toStringAsFixed(1)} h',
          icon: Icons.timer_rounded,
          color: AppColors.success,
          subtitle: 'هذا الشهر',
          onTap: () {
            // Navigate to payroll/hours detail
          },
        ),
        if (isDesktop || isTablet) ...[
          StatCard(
            title: 'الراتب التقديري',
            value: '---',
            icon: Icons.payments_rounded,
            color: Colors.amber,
            subtitle: 'شامل المكافآت',
          ),
          StatCard(
            title: 'التقييم',
            value: '5.0',
            icon: Icons.star_rounded,
            color: Colors.orange,
            subtitle: 'أداء متميز',
          ),
        ],
      ],
    );
  }

  Widget _buildAttendanceStatus(Map<String, dynamic> nurseData) {
    final AttendanceModel? attendance = nurseData['attendance'];
    final isCheckedIn = attendance != null;
    final isCheckedOut = attendance?.isCheckedOut ?? false;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCheckedOut
                  ? Colors.grey.withValues(alpha: 0.1)
                  : (isCheckedIn ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCheckedOut
                  ? Icons.done_all_rounded
                  : (isCheckedIn ? Icons.timer_rounded : Icons.timer_outlined),
              color: isCheckedOut
                  ? Colors.grey
                  : (isCheckedIn ? AppColors.success : AppColors.primary),
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCheckedOut
                      ? 'انتهت فترة العمل'
                      : (isCheckedIn ? 'أنت قيد العمل حالياً' : 'لم يتم تسجيل الحضور بعد'),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCheckedOut
                      ? 'تم تسجيل الانصراف بنجاح'
                      : (isCheckedIn ? 'نأمل لك يوماً سعيداً في العمل' : 'يرجى مسح الـ QR عند الوصول'),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isCheckedIn)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _attendanceInfoSmall('حضر في', attendance.checkInTime),
                if (isCheckedOut)
                  _attendanceInfoSmall('انصرف في', attendance.checkOutTime!),
              ],
            ),
        ],
      ),
    );
  }

  Widget _attendanceInfoSmall(String label, DateTime time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            DateFormat('hh:mm a', 'ar').format(time),
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule(Map<String, dynamic> nurseData) {
    final List<CaseModel> cases = List<CaseModel>.from(
      nurseData['todayCasesList'] ?? [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'جدول حالات اليوم',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to Cases screen with personal filter?
              },
              child: const Text(
                'عرض الكل',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
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
                Icon(
                  Icons.event_available_rounded,
                  size: 48,
                  color: AppColors.textHint.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا يوجد حالات مسجلة لك اليوم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cases.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
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
            child: const Icon(
              Icons.person_pin_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.patientName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  c.patientAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
