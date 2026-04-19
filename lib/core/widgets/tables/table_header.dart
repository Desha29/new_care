import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';

/// رأس عمود الجدول - Sortable Table Header
/// عمود جدول قابل للفرز مع سهم الاتجاه
class TableHeader extends StatelessWidget {
  final String label;
  final bool isSorted;
  final bool ascending;
  final VoidCallback? onTap;
  final TextAlign textAlign;

  const TableHeader({
    super.key,
    required this.label,
    this.isSorted = false,
    this.ascending = true,
    this.onTap,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppTypography.tableHeader.copyWith(
                  color: isSorted ? AppColors.primary : AppColors.textPrimary,
                ),
                textAlign: textAlign,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                isSorted
                    ? (ascending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded)
                    : Icons.unfold_more_rounded,
                size: 16,
                color: isSorted ? AppColors.primary : AppColors.textHint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
