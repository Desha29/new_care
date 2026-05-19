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
import '../../../cases/presentation/cubit/cases_cubit.dart';
import '../../../cases/presentation/cubit/cases_state.dart';
import 'package:new_care/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:new_care/features/attendance/presentation/cubit/attendance_state.dart';

class NurseDashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAll;
  const NurseDashboardScreen({super.key, this.onViewAll});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
  int todayCasesCount = 0;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().currentUser;
    if (user != null) {
      // Initialize dashboard data
      context.read<DashboardCubit>().loadNurseDashboardData(user.id);

      // Initialize attendance listener for the nurse's account
      context.read<AttendanceCubit>().init(userId: user.id);
      // Also check today's status for real-time updates
      context.read<AttendanceCubit>().checkTodayStatus(user.id);
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
                  await context.read<DashboardCubit>().loadNurseDashboardData(
                    user.id,
                    force: true,
                  );
                  // Also refresh attendance data when user pulls to refresh
                  context.read<AttendanceCubit>().loadTodayAttendance(
                    userId: user.id,
                  );
                  context.read<AttendanceCubit>().checkTodayStatus(user.id);
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
                          _buildAttendanceBanner(),
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
                          // Reactive Today's Schedule
                          BlocBuilder<CasesCubit, CasesState>(
                            builder: (context, state) {
                              return _buildTodaySchedule(state);
                            },
                          ),
                          const SizedBox(height: 100),
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

  Widget _buildStaffStats(
    Map<String, dynamic> nurseData,
    CasesState casesState,
    AttendanceState attState,
  ) {
    int outsideCasesMonth = 0;
    final user = context.read<AuthCubit>().currentUser;
    final now = DateTime.now();

    if (casesState is CasesLoaded) {
      todayCasesCount = casesState.cases.where((c) {
        return c.nurseId == user?.id &&
            c.caseDate.year == now.year &&
            c.caseDate.month == now.month &&
            c.caseDate.day == now.day;
      }).length;

      outsideCasesMonth = casesState.cases.where((c) {
        return c.nurseId == user?.id &&
            c.caseType.value == 'home_visit' &&
            c.caseDate.year == now.year &&
            c.caseDate.month == now.month;
      }).length;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final isTablet =
            constraints.maxWidth > 500 && constraints.maxWidth <= 800;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 2),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isDesktop ? 2.0 : 1.4,
          children: [
            StatCard(
              title: 'حالات اليوم',
              value: '$todayCasesCount',
              icon: Icons.assignment_ind_rounded,
              color: AppColors.primary,
              subtitle: 'إجمالي المهام اليومية',
            ),
            StatCard(
              title: 'زيارات منزلية',
              value: '$outsideCasesMonth',
              icon: Icons.home_work_rounded,
              color: Colors.deepPurple,
              subtitle: 'إجمالي الشهر الحالي',
            ),
            StatCard(
              title: 'حالات المركز',
              value: '${nurseData['inCenterCases'] ?? 0}',
              icon: Icons.local_hospital_rounded,
              color: AppColors.secondary,
              subtitle: 'إجمالي الحالات الداخلية',
            ),
            StatCard(
              title: 'أيام الحضور',
              value: '${nurseData['attendanceDays'] ?? 0}',
              icon: Icons.calendar_today_rounded,
              color: AppColors.success,
              subtitle: 'خلال الشهر الحالي',
            ),
          ],
        );
      },
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
              onPressed: widget.onViewAll,
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

  Widget _buildAttendanceBanner() {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        bool isCheckedIn = false;
        DateTime? checkInTime;

        if (state is AttendanceLoaded) {
          isCheckedIn = state.isCheckedIn;
          checkInTime = state.todayRecord?.checkInTime;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCheckedIn
                  ? [AppColors.primary, AppColors.primaryDark]
                  : [Colors.grey[800]!, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isCheckedIn ? AppColors.primary : Colors.black)
                    .withValues(alpha: 0.3),
                blurRadius: 15,
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
                      isCheckedIn ? 'أنت في نوبة عمل' : 'لم يتم بدء الوردية',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCheckedIn
                          ? 'بدأت العمل الساعة ${DateFormat('hh:mm a', 'ar').format(checkInTime!)}'
                          : 'لم يتم تسجيل الحضور بعد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleItem(CaseModel c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_pin_rounded,
              color: AppColors.primary,
              size: 24,
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
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${c.caseType.label} • ${c.patientAddress}',
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
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }
}
