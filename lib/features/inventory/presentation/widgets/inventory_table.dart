import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/buttons/icon_action_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/inventory_model.dart';

class InventoryTable extends StatelessWidget {
  final List<InventoryModel> items;
  final Function(InventoryModel) onEdit;
  final Function(InventoryModel) onAddStock;
  final Function(InventoryModel) onDelete;
  final VoidCallback onEmptyAction;

  const InventoryTable({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onAddStock,
    required this.onDelete,
    required this.onEmptyAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = constraints.maxWidth < 800 ? 800.0 : constraints.maxWidth;
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minWidth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        _hc('المستلزم', 3),
                        _hc('التصنيف', 2),
                        _hc('الوحدة', 1),
                        _hc('الكمية', 1),
                        _hc('الحد الأدنى', 1),
                        _hc('السعر', 1),
                        _hc('حالة المخزون', 2),
                        _hc('إجراءات', 2),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: items.isEmpty
                    ? EmptyStateWidget.inventory(onAction: onEmptyAction)
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: minWidth,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: AppColors.borderLight),
                            itemBuilder: (context, i) => _row(context, items[i], i),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hc(String t, int f) => Expanded(
        flex: f,
        child: Text(
          t,
          style: AppTypography.tableHeader.copyWith(
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      );

  Widget _row(BuildContext context, InventoryModel item, int i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven
          ? Colors.transparent
          : AppColors.surfaceVariant.withOpacity(0.3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.category,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              item.unit,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.quantity}',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: item.isOutOfStock
                    ? AppColors.error
                    : item.isLowStock
                        ? AppColors.warning
                        : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.minStock}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.price.toStringAsFixed(0)} ${AppStrings.currency}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: StockBadge(
              quantity: item.quantity,
              minStock: item.minStock,
              fontSize: 11,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconActionButton.edit(onPressed: () => onEdit(item)),
                const SizedBox(width: 4),
                IconActionButton(
                  icon: Icons.add_circle_rounded,
                  tooltip: 'إضافة كمية',
                  color: AppColors.success,
                  onPressed: () => onAddStock(item),
                ),
                const SizedBox(width: 4),
                IconActionButton.delete(onPressed: () => onDelete(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

