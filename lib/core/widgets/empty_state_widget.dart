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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize + 40,
              height: iconSize + 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
