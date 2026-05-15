import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final titleSize = ResponsiveHelper.getTitleFontSize(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppStrings.dashboard,
                  style: AppTypography.pageTitle.copyWith(fontSize: titleSize),
                ),
                const SizedBox(width: 12),
                BlocBuilder<DashboardCubit, DashboardState>(
                  builder: (context, state) {
                    if (state is DashboardLoaded) {
                      return InkWell(
                        onTap: () async {
                          final cubit = context.read<DashboardCubit>();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: state.selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                            locale: const Locale('ar'),
                          );
                          if (date != null) {
                            cubit.loadDashboardData(date: date, force: true);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('yMMMMd', 'ar').format(state.selectedDate),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            Text(
              'نظرة عامة على أداء المركز',
              style: AppTypography.pageSubtitle.copyWith(
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

}

