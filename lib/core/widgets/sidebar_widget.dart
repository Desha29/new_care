import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/ui_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../logic/connectivity_cubit.dart';
import '../../features/cases/presentation/cubit/cases_cubit.dart';
import '../../features/cases/presentation/cubit/cases_state.dart';
import '../../features/procedures/presentation/cubit/procedures_cubit.dart';
import '../../features/procedures/presentation/cubit/procedures_state.dart';
import '../../features/inventory/presentation/cubit/inventory_cubit.dart';
import '../../features/inventory/presentation/cubit/inventory_state.dart';
import '../../features/users/presentation/cubit/users_cubit.dart';
import '../../features/users/presentation/cubit/users_state.dart';
import '../../features/shifts/presentation/cubit/shift_cubit.dart';
import '../../features/shifts/presentation/cubit/shift_state.dart';
import '../../features/financials/presentation/cubit/financials_cubit.dart';
import '../../features/payroll/presentation/cubit/payroll_cubit.dart';
import '../../features/payroll/presentation/cubit/payroll_state.dart';

/// نموذج عنصر الشريط الجانبي
class _SidebarItem {
  final IconData icon;
  final String label;
  final int index; // Real index in MainLayout screens
  final List<String>? roles;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
    this.roles,
  });
}

/// الشريط الجانبي - Sidebar Navigation Widget
/// تصميم احترافي للتنقل الرئيسي في التطبيق
class SidebarWidget extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String userName;
  final String userId;
  final String userRole;
  final String userRoleLabel;

  const SidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userName,
    required this.userId,
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

  final List<dynamic> _items = [
    'الرئيسية',
    _SidebarItem(icon: Icons.dashboard_rounded, label: AppStrings.dashboard, index: 0),
    _SidebarItem(icon: Icons.assignment_rounded, label: AppStrings.cases, index: 1),
    _SidebarItem(icon: Icons.fingerprint_rounded, label: 'الحضور والانصراف', index: 2),
    
    'إدارة المركز',
    _SidebarItem(icon: Icons.event_note_rounded, label: 'إدارة الورديات', index: 3, roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.medical_services_rounded, label: 'الخدمات والإجراءات', index: 4, roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.person_rounded, label: AppStrings.users, index: 8, roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.inventory_2_rounded, label: AppStrings.inventory, index: 9, roles: ['admin', 'super_admin']),
    
    'المالية والرواتب',
    _SidebarItem(icon: Icons.account_balance_rounded, label: 'المالية', index: 5, roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.payments_rounded, label: 'الرواتب', index: 6, roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.payments_rounded, label: 'راتبي الشخصي', index: 6, roles: ['nurse']),
    
    'النظام والتقارير',
    _SidebarItem(icon: Icons.assessment_rounded, label: 'التقارير', index: 7, roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.history_rounded, label: AppStrings.activityLogs, index: 10, roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.settings_rounded, label: AppStrings.settings, index: 11, roles: ['admin', 'super_admin']),
    _SidebarItem(icon: Icons.analytics_rounded, label: 'حالة البيانات', index: 12, roles: ['admin', 'super_admin']),
  ];

  List<dynamic> get _filteredItems {
    final List<dynamic> filtered = [];
    String? currentHeader;

    for (var item in _items) {
      if (item is String) {
        currentHeader = item;
        continue;
      }
      
      final sidebarItem = item as _SidebarItem;
      bool hasAccess = true;
      if (sidebarItem.roles != null) {
        hasAccess = sidebarItem.roles!.contains(widget.userRole.toLowerCase());
      }

      if (hasAccess) {
        if (currentHeader != null) {
          filtered.add(currentHeader);
          currentHeader = null;
        }
        filtered.add(sidebarItem);
      }
    }
    return filtered;
  }

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
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    if (item is String) {
                      return _buildSectionHeader(item, isNarrow);
                    }
                    return _buildMenuItem(index, isNarrow);
                  },
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
                    errorBuilder: (context, error, stackTrace) => const Icon(
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
  Widget _buildMenuItem(int itemIndex, bool isNarrow) {
    final item = _filteredItems[itemIndex] as _SidebarItem;
    final isSelected = widget.selectedIndex == item.index;
    final isHovered = _hoveredIndex == itemIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = itemIndex),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        child: Tooltip(
          message: isNarrow ? item.label : '',
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 400),
          child: GestureDetector(
            onTap: () => widget.onItemSelected(item.index),
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
                        // === Counters ===
                        if (item.label == AppStrings.cases)
                          _buildCasesCounter()
                        else if (item.label == 'الخدمات والإجراءات')
                          _buildProceduresCounter()
                        else if (item.label == AppStrings.inventory)
                          _buildInventoryCounter()
                        else if (item.label == AppStrings.users)
                          _buildUsersCounter()
                        else if (item.label == 'إدارة الورديات')
                          _buildShiftsCounter()
                        else if (item.label == 'المالية')
                          _buildFinancialsCounter()
                        else if (item.label == 'الرواتب')
                          _buildPayrollCounter()
                        else if (isSelected)
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

  Widget _buildSectionHeader(String title, bool isNarrow) {
    if (isNarrow) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(
          color: Colors.white.withValues(alpha: 0.1),
          indent: 8,
          endIndent: 8,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, right: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// Case counter badge widget
  Widget _buildCasesCounter() {
    return BlocBuilder<CasesCubit, CasesState>(
      builder: (context, state) {
        if (state is CasesLoaded && state.cases.isNotEmpty) {
          final isAdmin =
              widget.userRole.toLowerCase() == 'admin' ||
              widget.userRole.toLowerCase() == 'super_admin';

          final count = isAdmin
              ? state.cases.length
              : state.cases.where((c) => c.nurseId == widget.userId).length;

          if (count == 0) return const SizedBox.shrink();
          return _buildBadge(count);
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Procedures counter badge
  Widget _buildProceduresCounter() {
    return BlocBuilder<ProceduresCubit, ProceduresState>(
      builder: (context, state) {
        if (state is ProceduresLoaded && state.procedures.isNotEmpty) {
          return _buildBadge(state.procedures.length);
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Inventory counter badge
  Widget _buildInventoryCounter() {
    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoaded && state.items.isNotEmpty) {
          return _buildBadge(state.items.length);
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Users counter badge
  Widget _buildUsersCounter() {
    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        if (state is UsersLoaded && state.users.isNotEmpty) {
          return _buildBadge(state.users.length);
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Shifts counter badge
  Widget _buildShiftsCounter() {
    return BlocBuilder<ShiftCubit, ShiftState>(
      builder: (context, state) {
        if (state is ShiftLoaded && state.shifts.isNotEmpty) {
          return _buildBadge(state.shifts.length);
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Financials total income badge
  Widget _buildFinancialsCounter() {
    return BlocBuilder<FinancialsCubit, FinancialsState>(
      builder: (context, state) {
        if (state is FinancialsLoaded && state.totalIncome > 0) {
          return _buildAmountBadge(state.totalIncome);
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Payroll total salaries badge
  Widget _buildPayrollCounter() {
    return BlocBuilder<PayrollCubit, PayrollState>(
      builder: (context, state) {
        if (state is PayrollLoaded && state.payrolls.isNotEmpty) {
          return _buildAmountBadge(state.totalSalaries);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  /// Badge for monetary amounts (formatted with K for thousands)
  Widget _buildAmountBadge(double amount) {
    String formatted;
    if (amount >= 1000) {
      formatted = '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      formatted = amount.toStringAsFixed(0);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        formatted,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
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
                      const SizedBox(height: 4),
                      _buildConnectivityStatus(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// مؤشر حالة الاتصال - Connectivity Status Indicator
  Widget _buildConnectivityStatus() {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, state) {
        final isOnline = state == ConnectivityStatus.online;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (isOnline ? Colors.green : Colors.red).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: (isOnline ? Colors.green : Colors.red).withValues(
                alpha: 0.3,
              ),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? Colors.green : Colors.red).withValues(
                        alpha: 0.5,
                      ),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isOnline ? 'متصل' : 'غير متصل',
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.red,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        );
      },
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
