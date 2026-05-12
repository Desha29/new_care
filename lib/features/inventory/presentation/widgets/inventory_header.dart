import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../cubit/inventory_cubit.dart';
import '../cubit/inventory_state.dart';

class InventoryHeader extends StatelessWidget {
  final InventoryState state;
  final VoidCallback onRefresh;
  final VoidCallback onAddItem;

  const InventoryHeader({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = ResponsiveHelper.getTitleFontSize(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    final categories = state is InventoryLoaded 
        ? (state as InventoryLoaded).items.map((e) => e.category).toSet().toList()
        : <String>[];

    return Column(
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.inventory,
                      style: AppTypography.pageTitle.copyWith(fontSize: titleSize),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                Text(
                  'إدارة ومتابعة المستلزمات الطبية والمخزون',
                  style: AppTypography.pageSubtitle.copyWith(
                    fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                  ),
                ),
              ],
            ),
            const Spacer(),
            PrimaryButton(
              label: isMobile ? 'إضافة' : AppStrings.addItem,
              icon: Icons.add_rounded,
              onPressed: onAddItem,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SearchBarWidget(
          hintText: AppStrings.searchInventory,
          onChanged: (v) => context.read<InventoryCubit>().searchInventory(v),
          maxWidth: double.infinity,
          trailing: state is InventoryLoaded ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VerticalDivider(width: 1, indent: 10, endIndent: 10),
              DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: (state as InventoryLoaded).categoryFilter,
                  hint: const Text('التصنيف', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                  icon: const Icon(Icons.filter_list_rounded, size: 18, color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('الكل', style: TextStyle(fontFamily: 'Cairo'))),
                    ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontFamily: 'Cairo')))),
                  ],
                  onChanged: (v) => context.read<InventoryCubit>().filterByCategory(v),
                ),
              ),
            ],
          ) : null,
        ),
      ],
    );
  }
}
