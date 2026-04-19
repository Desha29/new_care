import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// حوار النموذج العام - Generic Form Dialog
/// حوار قابل لإعادة الاستخدام يحتوي على نموذج مع أزرار حفظ وإلغاء
class FormDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final String saveLabel;
  final String cancelLabel;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final bool isLoading;
  final double maxWidth;

  const FormDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.saveLabel = 'حفظ',
    this.cancelLabel = 'إلغاء',
    this.onSave,
    this.onCancel,
    this.isLoading = false,
    this.maxWidth = 500,
  });

  /// عرض حوار النموذج - Show form dialog
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? subtitle,
    required Widget content,
    String saveLabel = 'حفظ',
    String cancelLabel = 'إلغاء',
    VoidCallback? onSave,
    double maxWidth = 500,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => FormDialog(
        title: title,
        subtitle: subtitle,
        content: content,
        saveLabel: saveLabel,
        cancelLabel: cancelLabel,
        onSave: onSave,
        onCancel: () => Navigator.of(ctx).pop(),
        maxWidth: maxWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === العنوان - Title ===
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppSpacing.lg),

            // === المحتوى - Content ===
            Flexible(child: SingleChildScrollView(child: content)),

            const SizedBox(height: AppSpacing.xxl),

            // === الأزرار - Actions ===
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : (onCancel ?? () => Navigator.of(context).pop()),
                    child: Text(cancelLabel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSave,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : Text(saveLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
