import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../cubit/inventory_cubit.dart';
import '../cubit/inventory_state.dart';

class InventoryHeader extends StatelessWidget {
  final InventoryState state;
  final VoidCallback onRefresh;
  final VoidCallback onAddItem;
  final VoidCallback onGenerateReport;

  const InventoryHeader({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onAddItem,
    required this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isLoaded = state is InventoryLoaded;
    final loadedState = isLoaded ? state as InventoryLoaded : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Section (Title + Add Button)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.inventory,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إدارة ومتابعة المستلزمات الطبية والمخزون',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _headerActionButton(
                  icon: Icons.refresh_rounded,
                  onTap: onRefresh,
                  tooltip: 'تحديث البيانات',
                ),
                if (isLoaded) ...[
                  const SizedBox(width: 12),
                  _headerActionButton(
                    icon: Icons.assessment_rounded,
                    onTap: onGenerateReport,
                    tooltip: 'تصدير تقرير الجرد',
                  ),
                ],
                const SizedBox(width: 12),
                PrimaryButton(
                  label: isMobile ? 'إضافة' : AppStrings.addItem,
                  icon: Icons.add_rounded,
                  onPressed: onAddItem,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 2. Search and Filter Hub
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SearchBarWidget(
                      hintText: AppStrings.searchInventory,
                      onChanged: (v) => context.read<InventoryCubit>().searchInventory(v),
                      maxWidth: double.infinity,
                    ),
                  ),
                  if (!isMobile && isLoaded) ...[
                    const SizedBox(width: 16),
                    _buildCategoryFilter(context, loadedState!),
                  ],
                ],
              ),
              if (isLoaded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 16),
                _buildQuickFilters(context, loadedState!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerActionButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primary, size: 20),
        onPressed: onTap,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, InventoryLoaded state) {
    final categories = state.items.map((e) => e.category).toSet().toList();
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: state.categoryFilter,
          isExpanded: true,
          hint: const Text('التصنيف', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
          items: [
            const DropdownMenuItem(value: null, child: Text('جميع التصنيفات')),
            ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
          ],
          onChanged: (v) => context.read<InventoryCubit>().filterByCategory(v),
        ),
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context, InventoryLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _filterChip(
            label: 'الكل',
            icon: Icons.all_inclusive_rounded,
            isSelected: state.stockFilter == 'all' && state.expiryFilter == 'all',
            onTap: () {
              context.read<InventoryCubit>().setStockFilter('all');
              context.read<InventoryCubit>().setExpiryFilter('all');
            },
          ),
          const SizedBox(width: 10),
          _filterChip(
            label: 'مخزون منخفض',
            icon: Icons.warning_amber_rounded,
            isSelected: state.stockFilter == 'lowStock',
            color: Colors.orange,
            onTap: () => context.read<InventoryCubit>().setStockFilter('lowStock'),
          ),
          const SizedBox(width: 10),
          _filterChip(
            label: 'نفد المخزون',
            icon: Icons.error_outline_rounded,
            isSelected: state.stockFilter == 'outOfStock',
            color: Colors.red,
            onTap: () => context.read<InventoryCubit>().setStockFilter('outOfStock'),
          ),
          const SizedBox(width: 10),
          _filterChip(
            label: 'منتهية الصلاحية',
            icon: Icons.event_busy_rounded,
            isSelected: state.expiryFilter == 'expired',
            color: Colors.redAccent,
            onTap: () => context.read<InventoryCubit>().setExpiryFilter('expired'),
          ),
          const SizedBox(width: 10),
          _filterChip(
            label: 'تنتهي قريباً',
            icon: Icons.event_repeat_rounded,
            isSelected: state.expiryFilter == 'expiringSoon',
            color: Colors.amber,
            onTap: () => context.read<InventoryCubit>().setExpiryFilter('expiringSoon'),
          ),
          const SizedBox(width: 10),
          _filterChip(
            label: 'متوفر',
            icon: Icons.check_circle_outline_rounded,
            isSelected: state.stockFilter == 'healthy',
            color: AppColors.success,
            onTap: () => context.read<InventoryCubit>().setStockFilter('healthy'),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color color = AppColors.primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
