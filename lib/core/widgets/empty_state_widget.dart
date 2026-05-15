import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// حالة فارغة - Empty State Widget
/// يُعرض عندما لا توجد بيانات في القائمة أو الجدول
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
  });

  /// حالة فارغة للحالات - Empty cases
  factory EmptyStateWidget.cases({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.medical_services_rounded,
      title: 'لا توجد حالات',
      subtitle: 'ابدأ بإضافة حالة جديدة',
      actionLabel: 'إضافة حالة',
      onAction: onAction,
    );
  }

  /// حالة فارغة للمخزون - Empty inventory
  factory EmptyStateWidget.inventory({VoidCallback? onAction}) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_rounded,
      title: 'لا توجد مستلزمات',
      subtitle: 'ابدأ بإضافة مستلزم جديد',
      actionLabel: 'إضافة مستلزم',
      onAction: onAction,
    );
  }

  /// حالة فارغة للبحث - Empty search results
  factory EmptyStateWidget.search() {
    return const EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'لا توجد نتائج',
      subtitle: 'جرّب تغيير كلمات البحث',
    );
  }

  /// حالة خطأ - Error state
  factory EmptyStateWidget.error({String? message, VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.error_outline_rounded,
      title: 'حدث خطأ',
      subtitle: message ?? 'يرجى المحاولة مرة أخرى',
      actionLabel: 'إعادة المحاولة',
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize + 24,
              height: iconSize + 24,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize * 0.8,
                color: AppColors.textHint.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
