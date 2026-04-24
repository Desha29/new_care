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

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMobile)
              SearchBarWidget(
                hintText: AppStrings.searchInventory,
                controller: TextEditingController(),
                onChanged: (v) => context.read<InventoryCubit>().searchInventory(v),
              ),
            if (!isMobile) const SizedBox(width: 12),
            PrimaryButton(
              label: isMobile ? 'إضافة' : AppStrings.addItem,
              icon: Icons.add_rounded,
              onPressed: onAddItem,
            ),
          ],
        ),
        if (isMobile)
          SearchBarWidget(
            hintText: AppStrings.searchInventory,
            controller: TextEditingController(),
            onChanged: (v) => context.read<InventoryCubit>().searchInventory(v),
          ),
      ],
    );
  }
}
