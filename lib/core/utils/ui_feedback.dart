import 'package:flutter/material.dart';
import 'package:new_care/core/utils/app_toast.dart';
import 'package:new_care/core/constants/app_colors.dart';

/// كلاس التنبيهات والتعليقات البصرية - UI Feedback & Notifications
/// يوفر تصميماً عصرياً واحترافياً للتنبيهات والرسائل
class UIFeedback {
  UIFeedback._();

  /// عرض تنبيه نجاح - Success Toast
  static void showSuccess(BuildContext context, String message) {
    AppToast.showSuccess(context, message);
  }

  /// عرض تنبيه خطأ - Error Toast
  static void showError(BuildContext context, String message) {
    AppToast.showError(context, message);
  }

  /// عرض تنبيه تحذير - Warning Toast
  static void showWarning(BuildContext context, String message) {
    AppToast.showError(context, message); // Warning can use error color or we add warning to AppToast
  }

  /// عرض تنبيه معلومة - Info Toast
  static void showInfo(BuildContext context, String message) {
    AppToast.showInfo(context, message);
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

  /// عرض حوار تغيير كلمة المرور - Change Password Dialog
  static Future<String?> showChangePasswordDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'تغيير كلمة المرور',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أدخل كلمة المرور الجديدة (6 أحرف على الأقل)',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  obscureText: obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'يجب أن تكون 6 أحرف على الأقل' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, controller.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }
}

