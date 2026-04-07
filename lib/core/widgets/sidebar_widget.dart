import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/ui_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/logic/cubit/auth_cubit.dart';

/// نموذج عنصر الشريط الجانبي
class _SidebarItem {
  final IconData icon;
  final String label;
  final List<String>? roles;

  const _SidebarItem({required this.icon, required this.label, this.roles});
}

/// الشريط الجانبي - Sidebar Navigation Widget
/// تصميم احترافي للتنقل الرئيسي في التطبيق
class SidebarWidget extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String userName;
  final String userRole;
  final String userRoleLabel;

  const SidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userName,
    required this.userRole,
    required this.userRoleLabel,
  });

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  bool _isCollapsed = false;
  int _hoveredIndex = -1;

  static const double _showTextThreshold = 140.0;

  final List<_SidebarItem> _items = [
    _SidebarItem(icon: Icons.dashboard_rounded, label: AppStrings.dashboard),
    _SidebarItem(icon: Icons.people_rounded, label: AppStrings.patients),
    _SidebarItem(icon: Icons.medical_services_rounded, label: AppStrings.cases),
    _SidebarItem(icon: Icons.account_balance_rounded, label: 'المالية', roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.person_rounded, label: AppStrings.users, roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.inventory_2_rounded, label: AppStrings.inventory, roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.history_rounded, label: AppStrings.activityLogs, roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.settings_rounded, label: AppStrings.settings, roles: ['admin', 'super_admin']),
  ];

  List<_SidebarItem> get _filteredItems => _items.where((item) {
    if (item.roles == null) return true;
    return item.roles!.contains(widget.userRole.toLowerCase());
  }).toList();

  @override
  Widget build(BuildContext context) {
    final width = _isCollapsed
        ? AppConstants.sidebarCollapsedWidth
        : AppConstants.sidebarWidth;

    return AnimatedContainer(
      duration: AppConstants.animationNormal,
      curve: Curves.easeInOut,
      width: width,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: AppColors.sidebarGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(-2, 0),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < _showTextThreshold;

          return Column(
            children: [
              // === رأس الشريط الجانبي - Header ===
              _buildHeader(isNarrow),

              const SizedBox(height: 8),

              // === عناصر القائمة - Menu Items ===
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) =>
                      _buildMenuItem(index, isNarrow),
                ),
              ),

              // === معلومات المستخدم - User Info ===
              _buildUserInfo(isNarrow),
              
              // === تسجيل الخروج - Logout ===
              _buildLogoutButton(isNarrow),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  /// رأس الشريط الجانبي - Header with logo
  Widget _buildHeader(bool isNarrow) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 16),
      child: isNarrow
          ? Center(
              child: InkWell(
                onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.menu_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 22,
                  ),
                ),
              ),
            )
          : Row(
              children: [
                // الشعار
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_hospital_rounded,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        AppStrings.appSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontFamily: 'Cairo',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.menu_open_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// عنصر القائمة - Menu Item
  Widget _buildMenuItem(int index, bool isNarrow) {
    final item = _filteredItems[index];
    final isSelected = widget.selectedIndex == index;
    final isHovered = _hoveredIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        child: Tooltip(
          message: isNarrow ? item.label : '',
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 400),
          child: GestureDetector(
            onTap: () => widget.onItemSelected(index),
            child: AnimatedContainer(
              duration: AppConstants.animationFast,
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 0 : 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.sidebarItemActive.withValues(alpha: 0.15)
                    : isHovered
                    ? AppColors.sidebarItemHover.withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: AppColors.sidebarItemActive.withValues(
                          alpha: 0.3,
                        ),
                        width: 1,
                      )
                    : null,
              ),
              child: isNarrow
                  ? Center(
                      child: Icon(
                        item.icon,
                        color: isSelected
                            ? AppColors.sidebarItemActive
                            : isHovered
                            ? Colors.white
                            : AppColors.sidebarText,
                        size: 22,
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? AppColors.sidebarItemActive
                              : isHovered
                              ? Colors.white
                              : AppColors.sidebarText,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.sidebarTextActive
                                  : isHovered
                                  ? Colors.white
                                  : AppColors.sidebarText,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontFamily: 'Cairo',
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.sidebarItemActive,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// معلومات المستخدم - User Info Section
  Widget _buildUserInfo(bool isNarrow) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.all(isNarrow ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isNarrow
          ? Center(
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.3),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.3),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        widget.userRoleLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontFamily: 'Cairo',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// زر تسجيل الخروج - Logout Button
  Widget _buildLogoutButton(bool isNarrow) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () async {
          final confirm = await UIFeedback.showConfirmDialog(
            context: context,
            title: 'تسجيل الخروج',
            message: 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
            confirmLabel: 'خروج',
            isDestructive: true,
          );
          if (confirm && mounted) {
            context.read<AuthCubit>().logout();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 0 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isNarrow
              ? const Center(
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                )
              : Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
