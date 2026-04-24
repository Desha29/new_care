import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../cubit/dashboard_cubit.dart';

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
            Text(
              AppStrings.dashboard,
              style: AppTypography.pageTitle.copyWith(fontSize: titleSize),
            ),
            Text(
              'نظرة عامة على أداء المركز اليوم',
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
                onPressed: () => _showCenterQr(context, isDeparture: false),
                icon: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 20,
                  color: AppColors.secondary,
                ),
                tooltip: 'عرض كود حضور المركز',
              ),
              IconButton(
                onPressed: () => _showCenterQr(context, isDeparture: true),
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

  void _showCenterQr(BuildContext context, {required bool isDeparture}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isDeparture ? 'كود انصراف المركز' : 'كود حضور المركز',
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
                  data: isDeparture ? 'NEWCARE_DEPARTURE' : 'NEWCARE_ATTENDANCE',
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isDeparture
                    ? 'اطلب من الممرض مسح هذا الكود في نهاية نوبة العمل لتسجيل الانصراف'
                    : 'اطلب من الممرض مسح هذا الكود في بداية نوبة العمل لتسجيل الحضور',
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
