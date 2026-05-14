import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/enums/user_role.dart';
import '../cubit/users_cubit.dart';
import '../cubit/users_state.dart';

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
                width: 350,
                child: _buildSearchWithFilter(context),
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
          _buildSearchWithFilter(context),
        ],
      ],
    );
  }

  Widget _buildSearchWithFilter(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      buildWhen: (prev, curr) => curr is UsersLoaded,
      builder: (context, state) {
        final roleFilter = state is UsersLoaded ? state.roleFilter : null;
        
        return AppSearchBar(
          hintText: AppStrings.searchUsers,
          controller: searchController,
          onChanged: onSearchChanged,
          onFilterTap: () => _showRoleFilterMenu(context, roleFilter),
        );
      },
    );
  }

  void _showRoleFilterMenu(BuildContext context, UserRole? currentRole) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<UserRole?>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        const PopupMenuItem(
          value: null,
          child: Text('الكل (الصلاحيات)', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ...UserRole.values.map((role) => PopupMenuItem(
          value: role,
          child: Text(role.label, style: const TextStyle(fontFamily: 'Cairo')),
        )),
      ],
    ).then((role) {
      if (context.mounted && (role != null || currentRole != null)) {
        context.read<UsersCubit>().filterByRole(role);
      }
    });
  }
}
