import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../cases/data/models/case_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../../cases/presentation/widgets/case_form_dialog.dart';
import '../../../cases/presentation/cubit/cases_cubit.dart';
import '../../../cases/presentation/cubit/cases_state.dart';
import 'package:new_care/features/attendance/presentation/widgets/attendance_scanner_dialog.dart';
import 'package:new_care/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:new_care/features/attendance/presentation/cubit/attendance_state.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../widgets/dashboard_weekly_chart.dart';

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
          return Scaffold(body: Center(child: Text('Error: ${state.message}')));
        }

        if (state is DashboardLoaded) {
          final nurseData = state.stats;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  return context.read<DashboardCubit>().loadNurseDashboardData(
                    user.id,
                    force: true,
                  );
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
                          // Reactive Stats
                          BlocBuilder<CasesCubit, CasesState>(
                            builder: (context, casesState) {
                              return BlocBuilder<
                                AttendanceCubit,
                                AttendanceState
                              >(
                                builder: (context, attState) {
                                  return _buildStaffStats(
                                    nurseData,
                                    casesState,
                                    attState,
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Reactive Attendance Status
                          BlocBuilder<AttendanceCubit, AttendanceState>(
                            builder: (context, state) {
                              return _buildAttendanceStatus(state);
                            },
                          ),
                          const SizedBox(height: 24),
                          // Weekly Chart
                          DashboardWeeklyChart(
                            weeklyCounts: state.chartData['counts'] ?? List.filled(7, 0.0),
                          ),
                          const SizedBox(height: 24),
                          // Reactive Today's Schedule
                          BlocBuilder<CasesCubit, CasesState>(
                            builder: (context, state) {
                              return _buildTodaySchedule(state);
                            },
                          ),
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
      childAspectRatio: isDesktop ? 2.0 : 1.6,
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
        Row(
          children: [
            _buildDateChip(),
            const SizedBox(width: 12),
            if (user != null)
              IconButton.filledTonal(
                onPressed: () => _showPersonalQr(user),
                icon: const Icon(Icons.qr_code_rounded, size: 20),
                tooltip: 'كودي الشخصي',
              ),
          ],
        ),
      ],
    );
  }

  void _showPersonalQr(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'كودي الشخصي',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${user.id}',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            const Text(
              'امسح الكود لتسجيل الحضور/الانصراف',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
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

  Widget _buildStaffStats(
    Map<String, dynamic> nurseData,
    CasesState casesState,
    AttendanceState attState,
  ) {
    int todayCount = 0;
    int outsideCasesMonth = 0;
    
    final user = context.read<AuthCubit>().currentUser;
    final now = DateTime.now();

    if (casesState is CasesLoaded) {
      todayCount = casesState.cases.where((c) {
        return c.nurseId == user?.id &&
            c.caseDate.year == now.year &&
            c.caseDate.month == now.month &&
            c.caseDate.day == now.day;
      }).length;

      // Count outside cases (home visits) for the current month
      outsideCasesMonth = casesState.cases.where((c) {
        return c.nurseId == user?.id &&
            c.caseType.value == 'home_visit' && // Correct check for home_visit
            c.caseDate.year == now.year &&
            c.caseDate.month == now.month;
      }).length;
    }

    // Get current fee from local settings (async handled by FutureBuilder for simplicity here)
    return FutureBuilder<double>(
      future: SqliteService.instance.getOutsideCaseFee(),
      builder: (context, snapshot) {
        final fee = snapshot.data ?? 15.0;
        final extraIncome = outsideCasesMonth * fee;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            final isTablet = constraints.maxWidth > 500 && constraints.maxWidth <= 800;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 2),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.8 : 1.4,
              children: [
                StatCard(
                  title: 'حالات اليوم',
                  value: '$todayCount',
                  icon: Icons.assignment_ind_rounded,
                  color: AppColors.primary,
                  subtitle: 'إجمالي المهام اليومية',
                ),
                StatCard(
                  title: 'عمليات خارجية',
                  value: '$outsideCasesMonth',
                  icon: Icons.home_work_rounded,
                  color: Colors.deepPurple,
                  subtitle: 'هذا الشهر (زيارة منزلية)',
                ),
                StatCard(
                  title: 'دخل إضافي',
                  value: '${extraIncome.toStringAsFixed(0)} E.P',
                  icon: Icons.add_card_rounded,
                  color: AppColors.success,
                  subtitle: 'بواقع ${fee.toStringAsFixed(0)} للحالة',
                ),
                StatCard(
                  title: 'الراتب التقديري',
                  value: '${((nurseData['estimatedSalary'] ?? 0.0) + extraIncome).toStringAsFixed(0)} E.P',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.secondary,
                  subtitle: 'شامل البدلات',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceStatus(AttendanceState state) {
    bool isCheckedIn = false;
    DateTime? checkInTime;
    DateTime? checkOutTime;

    if (state is AttendanceLoaded) {
      isCheckedIn = state.isCheckedIn;
      checkInTime = state.todayRecord?.checkInTime;
      checkOutTime = state.todayRecord?.checkOutTime;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isCheckedIn ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCheckedIn ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isCheckedIn ? AppColors.success : AppColors.error,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCheckedIn
                      ? 'أنت في نوبة عمل الآن'
                      : 'لم يتم تسجيل الحضور بعد',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (isCheckedIn && checkInTime != null)
                  Text(
                    'تم تسجيل الدخول الساعة ${DateFormat('hh:mm a', 'ar').format(checkInTime)}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  const Text(
                    'برجاء مسح كود المركز لبدء الوردية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (isCheckedIn && checkOutTime == null)
            ElevatedButton.icon(
              onPressed: () {
                final user = context.read<AuthCubit>().currentUser;
                if (user != null) {
                  AttendanceScannerDialog.show(context, user);
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('تسجيل انصراف'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                foregroundColor: AppColors.error,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule(CasesState state) {
    List<CaseModel> todayCases = [];
    if (state is CasesLoaded) {
      final now = DateTime.now();
      final user = context.read<AuthCubit>().currentUser;
      todayCases = state.cases.where((c) {
        return c.nurseId == user?.id &&
            c.caseDate.year == now.year &&
            c.caseDate.month == now.month &&
            c.caseDate.day == now.day;
      }).toList();
    }

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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'عرض الكل',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (todayCases.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  color: AppColors.textHint,
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  'لا توجد حالات مجدولة لليوم',
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
            itemCount: todayCases.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = todayCases[index];
              return _buildScheduleItem(c);
            },
          ),
      ],
    );
  }

  Widget _buildScheduleItem(CaseModel c) {
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

