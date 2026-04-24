import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/buttons/primary_button.dart';

class UsersHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onAddUser;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;

  const UsersHeader({
    super.key,
    required this.onRefresh,
    required this.onAddUser,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = ResponsiveHelper.getTitleFontSize(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.users,
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
                    'إدارة حسابات المستخدمين والصلاحيات',
                    style: AppTypography.pageSubtitle.copyWith(
                      fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile)
              SizedBox(
                width: 300,
                child: SearchBarWidget(
                  hintText: AppStrings.searchUsers,
                  controller: searchController,
                  onChanged: onSearchChanged,
                ),
              ),
            const SizedBox(width: 12),
            PrimaryButton(
              label: isMobile ? 'إضافة' : AppStrings.addUser,
              icon: Icons.person_add_rounded,
              onPressed: onAddUser,
            ),
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 12),
          SearchBarWidget(
            hintText: AppStrings.searchUsers,
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ],
      ],
    );
  }
}
