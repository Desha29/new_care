import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';

/// الشريط الجانبي - Sidebar Navigation Widget
/// تصميم احترافي للتنقل الرئيسي في التطبيق
class SidebarWidget extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String userName;
  final String userRole;

  const SidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userName,
    required this.userRole,
  });

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  bool _isCollapsed = false;
  int _hoveredIndex = -1;

  // عناصر القائمة الجانبية - Sidebar items
  final List<_SidebarItem> _items = [
    _SidebarItem(icon: Icons.dashboard_rounded, label: AppStrings.dashboard),
    _SidebarItem(icon: Icons.people_rounded, label: AppStrings.patients),
    _SidebarItem(icon: Icons.medical_services_rounded, label: AppStrings.cases),
    _SidebarItem(icon: Icons.person_rounded, label: AppStrings.users),
    _SidebarItem(icon: Icons.inventory_2_rounded, label: AppStrings.inventory),
    _SidebarItem(icon: Icons.assessment_rounded, label: AppStrings.reports),
    _SidebarItem(icon: Icons.history_rounded, label: AppStrings.activityLogs),
    _SidebarItem(icon: Icons.settings_rounded, label: AppStrings.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final width = _isCollapsed
        ? AppConstants.sidebarCollapsedWidth
        : AppConstants.sidebarWidth;

    return AnimatedContainer(
      duration: AppConstants.animationNormal,
      curve: Curves.easeInOut,
      width: width,
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
      child: Column(
        children: [
          // === رأس الشريط الجانبي - Header ===
          _buildHeader(),

          const SizedBox(height: 8),

          // === عناصر القائمة - Menu Items ===
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _items.length,
              itemBuilder: (context, index) => _buildMenuItem(index),
            ),
          ),

          // === معلومات المستخدم - User Info ===
          _buildUserInfo(),
        ],
      ),
    );
  }

  /// رأس الشريط الجانبي - Header with logo
  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // أيقونة التصغير/التوسيع
          if (!_isCollapsed) ...[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: AppColors.secondary,
                size: 24,
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
                  ),
                  Text(
                    AppStrings.appSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
          // زر التصغير
          InkWell(
            onTap: () => setState(() => _isCollapsed = !_isCollapsed),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _isCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
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
  Widget _buildMenuItem(int index) {
    final item = _items[index];
    final isSelected = widget.selectedIndex == index;
    final isHovered = _hoveredIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        child: GestureDetector(
          onTap: () => widget.onItemSelected(index),
          child: AnimatedContainer(
            duration: AppConstants.animationFast,
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 12 : 16,
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
                  ? Border.all(color: AppColors.sidebarItemActive.withValues(alpha: 0.3), width: 1)
                  : null,
            ),
            child: Row(
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
                if (!_isCollapsed) ...[
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontFamily: 'Cairo',
                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// معلومات المستخدم - User Info Section
  Widget _buildUserInfo() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.all(_isCollapsed ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: _isCollapsed ? 16 : 18,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.3),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.secondary,
              size: _isCollapsed ? 18 : 20,
            ),
          ),
          if (!_isCollapsed) ...[
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
                  ),
                  Text(
                    widget.userRole,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// نموذج عنصر الشريط الجانبي
class _SidebarItem {
  final IconData icon;
  final String label;

  const _SidebarItem({required this.icon, required this.label});
}
