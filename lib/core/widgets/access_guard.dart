import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/logic/cubit/auth_cubit.dart';
import '../../features/auth/logic/cubit/auth_state.dart';
import '../../features/attendance/logic/cubit/attendance_cubit.dart';
import '../../features/attendance/logic/cubit/attendance_state.dart';
import '../constants/app_colors.dart';

/// حارس الوصول - Access Guard Widget
/// يتحقق من: الوردية + الحضور + الجهاز قبل السماح بالوصول
/// Wraps content and verifies: shift + attendance + device before granting access
class AccessGuard extends StatefulWidget {
  final Widget child;
  final Widget? blockedWidget; // ودجت بديل عند المنع (اختياري)
  final bool requireShift;
  final bool requireAttendance;
  final bool requireDeviceCheck;
  final String? requiredPermission; // مثل 'canAccessCases', 'canAccessInventory'

  const AccessGuard({
    super.key,
    required this.child,
    this.blockedWidget,
    this.requireShift = true,
    this.requireAttendance = true,
    this.requireDeviceCheck = true,
    this.requiredPermission,
  });

  @override
  State<AccessGuard> createState() => _AccessGuardState();
}

class _AccessGuardState extends State<AccessGuard> {
  AccessVerificationResult? _verificationResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      setState(() {
        _isLoading = false;
        _verificationResult = const AccessVerificationResult(
          hasShift: false,
          isCheckedIn: false,
          isCorrectDevice: false,
          isGranted: false,
          message: 'غير مسجل دخول',
        );
      });
      return;
    }

    final user = authState.user;

    // المدير العام والمشرف: وصول مباشر
    if (user.role.isAdmin || user.role.isSuperAdmin) {
      setState(() {
        _isLoading = false;
        _verificationResult = const AccessVerificationResult(
          hasShift: true,
          isCheckedIn: true,
          isCorrectDevice: true,
          isGranted: true,
          message: 'وصول إداري',
        );
      });
      return;
    }

    // الممرض: تحقق كامل
    final result = await context.read<AttendanceCubit>().verifyAccess(user: user);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _verificationResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'جاري التحقق من الصلاحيات...',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final result = _verificationResult;
    if (result == null || !result.isGranted) {
      return widget.blockedWidget ?? _buildBlockedScreen(result);
    }

    return widget.child;
  }

  /// شاشة المنع - Blocked access screen
  Widget _buildBlockedScreen(AccessVerificationResult? result) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: AppColors.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'الوصول مرفوض',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result?.message ?? 'ليس لديك صلاحية للوصول',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),

              // حالة التحقق - Verification status indicators
              if (result != null) ...[
                _buildStatusRow(
                  'وردية اليوم',
                  result.hasShift,
                  Icons.calendar_today_rounded,
                ),
                const SizedBox(height: 8),
                _buildStatusRow(
                  'تسجيل الحضور',
                  result.isCheckedIn,
                  Icons.fingerprint_rounded,
                ),
                const SizedBox(height: 8),
                _buildStatusRow(
                  'الجهاز المصرح',
                  result.isCorrectDevice,
                  Icons.phone_android_rounded,
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _verify,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isOk, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOk
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isOk ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isOk ? AppColors.success : AppColors.error,
            size: 20,
          ),
        ],
      ),
    );
  }
}
