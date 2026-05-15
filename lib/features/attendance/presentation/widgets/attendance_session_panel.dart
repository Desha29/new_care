import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';

class AttendanceSessionPanel extends StatelessWidget {
  final AttendanceLoaded state;

  const AttendanceSessionPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final session = state.activeSession;
    final isActive = session != null && session.isActive;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'نظام تسجيل الحضور بالـ QR',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isActive
                ? 'يرجى من الموظفين مسح الكود أدناه'
                : 'لا توجد جلسة حضور نشطة حالياً',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          if (isActive)
            _buildQrDisplay(context, session.id, session.qrSecret)
          else
            _buildEmptyQr(context),
          const SizedBox(height: 32),
          _buildActionButtons(context, isActive),
        ],
      ),
    );
  }

  Widget _buildQrDisplay(BuildContext context, String sessionId, String secret) {
    // QR contains: sessionId|timestamp|secret
    final data = '$sessionId|${DateTime.now().millisecondsSinceEpoch}|$secret';
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: 240.0,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.primary,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'يتحدث تلقائياً كل 45 ثانية',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyQr(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'قم ببدء الجلسة لإظهار الكود',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isActive) {
    return SizedBox(
      width: double.infinity,
      child: isActive
          ? OutlinedButton.icon(
              onPressed: () => context.read<AttendanceCubit>().endCurrentSession(),
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              label: const Text('إنهاء جلسة الحضور', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          : ElevatedButton.icon(
              onPressed: () {
                final authState = context.read<AuthCubit>().state;
                if (authState is AuthAuthenticated) {
                  context.read<AttendanceCubit>().startNewSession(authState.user.id);
                }
              },
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('بدء جلسة حضور جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
    );
  }
}
