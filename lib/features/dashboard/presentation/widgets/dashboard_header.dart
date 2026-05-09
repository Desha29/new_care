import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
                            color: AppColors.primary.withOpacity(0.1),
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
        // أزرار سريعة - Quick Action Buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'كود المركز:',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showCenterQr(context, type: 'unified'),
                icon: const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                tooltip: 'عرض كود المركز الموحد',
              ),
              IconButton(
                onPressed: () => _showCenterQr(context, type: 'attendance'),
                icon: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 20,
                  color: AppColors.secondary,
                ),
                tooltip: 'عرض كود حضور المركز',
              ),
              IconButton(
                onPressed: () => _showCenterQr(context, type: 'departure'),
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                tooltip: 'عرض كود انصراف المركز',
              ),
              IconButton(
                onPressed: () => context.read<DashboardCubit>().loadDashboardData(),
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCenterQr(BuildContext context, {required String type}) {
    String title = 'كود المركز';
    String data = 'NEWCARE_UNIFIED';
    String subtitle = 'اطلب من الممرض مسح هذا الكود لتسجيل الحضور أو الانصراف';

    if (type == 'attendance') {
      title = 'كود حضور المركز';
      data = 'NEWCARE_ATTENDANCE';
      subtitle = 'اطلب من الممرض مسح هذا الكود في بداية نوبة العمل لتسجيل الحضور';
    } else if (type == 'departure') {
      title = 'كود انصراف المركز';
      data = 'NEWCARE_DEPARTURE';
      subtitle = 'اطلب من الممرض مسح هذا الكود في نهاية نوبة العمل لتسجيل الانصراف';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

