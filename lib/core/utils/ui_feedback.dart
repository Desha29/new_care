import 'package:flutter/material.dart';
import 'package:new_care/core/constants/app_colors.dart';

/// كلاس التنبيهات والتعليقات البصرية - UI Feedback & Notifications
/// يوفر تصميماً عصرياً واحترافياً للتنبيهات والرسائل
class UIFeedback {
  UIFeedback._();

  /// عرض تنبيه نجاح - Success SnackBar
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      AppColors.success,
      Icons.check_circle_rounded,
    );
  }

  /// عرض تنبيه خطأ - Error SnackBar
  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      AppColors.error,
      Icons.error_outline_rounded,
    );
  }

  /// عرض تنبيه تحذير - Warning SnackBar
  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      AppColors.warning,
      Icons.warning_amber_rounded,
    );
  }

  /// عرض تنبيه معلومة - Info SnackBar
  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      AppColors.info,
      Icons.info_outline_rounded,
    );
  }

  /// التصميم العام للتنبيهات - Common SnackBar Design
  static void _showSnackBar(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars(); // Clear all current and pending snackbars
    
    messenger.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3), // Reduced duration
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white.withOpacity(0.9),
          onPressed: () {
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// عرض حوار تأكيد - Confirmation Dialog (Modern Design)
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'تأكيد',
    String cancelLabel = 'إلغاء',
    bool isDestructive = false,
  }) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  cancelLabel,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
