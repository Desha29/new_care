import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// زر أيقونة مع نص - Icon Action Button
/// زر صغير يحتوي على أيقونة مع نص اختياري (للجداول والبطاقات)
class IconActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;
  final double iconSize;
  final bool isCircle;

  const IconActionButton({
    super.key,
    required this.icon,
    this.label,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.tooltip,
    this.iconSize = 18,
    this.isCircle = false,
  });

  /// زر التعديل - Edit button
  factory IconActionButton.edit({VoidCallback? onPressed}) {
    return IconActionButton(
      icon: Icons.edit_rounded,
      tooltip: 'تعديل',
      color: AppColors.info,
      onPressed: onPressed,
    );
  }

  /// زر الحذف - Delete button
  factory IconActionButton.delete({VoidCallback? onPressed}) {
    return IconActionButton(
      icon: Icons.delete_rounded,
      tooltip: 'حذف',
      color: AppColors.error,
      onPressed: onPressed,
    );
  }

  /// زر العرض - View button
  factory IconActionButton.view({VoidCallback? onPressed}) {
    return IconActionButton(
      icon: Icons.visibility_rounded,
      tooltip: 'عرض',
      color: AppColors.primary,
      onPressed: onPressed,
    );
  }

  /// زر الطباعة - Print button
  factory IconActionButton.print({VoidCallback? onPressed}) {
    return IconActionButton(
      icon: Icons.print_rounded,
      tooltip: 'طباعة',
      color: AppColors.secondary,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textSecondary;
    final effectiveBg = backgroundColor ?? effectiveColor.withValues(alpha: 0.08);

    Widget button;

    if (label != null) {
      // زر مع نص
      button = TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize, color: effectiveColor),
        label: Text(
          label!,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: effectiveColor,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: effectiveBg,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      );
    } else {
      // زر أيقونة فقط
      button = Material(
        color: isCircle ? effectiveBg : Colors.transparent,
        shape: isCircle ? const CircleBorder() : null,
        borderRadius: isCircle ? null : BorderRadius.circular(AppSpacing.radiusSm),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            isCircle ? AppSpacing.radiusRound : AppSpacing.radiusSm,
          ),
          child: Padding(
            padding: EdgeInsets.all(isCircle ? 8 : 6),
            child: Icon(icon, size: iconSize, color: effectiveColor),
          ),
        ),
      );
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
