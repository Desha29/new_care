import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class AttendanceHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onGenerateReport;

  const AttendanceHeader({
    super.key,
    required this.onRefresh,
    required this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = ResponsiveHelper.getTitleFontSize(context);
    final authState = context.read<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.role.isAdmin;

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
          ElevatedButton.icon(
            onPressed: () => _showCenterQr(context, isDeparture: false),
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('كود الحضور', style: TextStyle(fontFamily: 'Cairo')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showCenterQr(context, isDeparture: true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('كود الانصراف', style: TextStyle(fontFamily: 'Cairo')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onGenerateReport,
            icon: const Icon(Icons.print_rounded, size: 18),
            label: Text(
              ResponsiveHelper.isMobile(context) ? 'تقرير' : 'تقرير شهري',
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
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
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
                    ? 'اطلب من الممرض مسح هذا الكود عند نهاية نوبة العمل لتسجيل الانصراف'
                    : 'اطلب من الممرض مسح هذا الكود عند بداية نوبة العمل لتسجيل الحضور',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary),
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
