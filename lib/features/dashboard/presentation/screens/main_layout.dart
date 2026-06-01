import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_care/core/constants/app_colors.dart';
import 'package:new_care/core/utils/responsive_helper.dart';
import 'package:new_care/core/widgets/sidebar_widget.dart';
import 'package:new_care/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:new_care/features/auth/presentation/cubit/auth_state.dart';
import 'package:new_care/features/auth/presentation/screens/login_screen.dart';
import 'package:new_care/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:new_care/features/cases/presentation/screens/cases_screen.dart';
import 'package:new_care/features/procedures/presentation/screens/procedures_screen.dart';
import 'package:new_care/features/users/presentation/screens/users_screen.dart';
import 'package:new_care/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:new_care/features/financials/presentation/screens/financials_screen.dart';
import 'package:new_care/features/activity_logs/presentation/screens/logs_screen.dart';
import 'package:new_care/features/settings/presentation/screens/settings_screen.dart';
import 'package:new_care/features/settings/presentation/screens/data_status_screen.dart';
import 'package:new_care/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:new_care/features/shifts/presentation/screens/shift_management_screen.dart';
import 'package:new_care/features/payroll/presentation/screens/payroll_screen.dart';

/// التخطيط الرئيسي - Main Layout
/// يحتوي على الشريط الجانبي والمحتوى الرئيسي
/// يتكيف مع أحجام الشاشات المختلفة (موبايل، تابلت، سطح مكتب)
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> _getAvailableScreens(String role) {
    final dashboard = DashboardScreen(
      onViewAllCases: () => setState(() => _selectedIndex = 1),
    );

    if (role == 'admin' || role == 'super_admin') {
      return [
        dashboard, // 0
        const CasesScreen(), // 1
        const AttendanceScreen(), // 2 - الحضور والانصراف
        const ShiftManagementScreen(), // 3 - إدارة الورديات
        const ProceduresScreen(), // 4
        const FinancialsScreen(), // 5
        const PayrollScreen(), // 6 - الرواتب
        const UsersScreen(), // 7
        const InventoryScreen(), // 8
        const LogsScreen(), // 9
        const SettingsScreen(), // 10
        const DataStatusScreen(), // 11
      ];
    } else {
      return [
        dashboard,
        const CasesScreen(),
        const AttendanceScreen(), // الحضور متاح للممرضين
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final useDrawer = ResponsiveHelper.shouldShowDrawer(context);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        // === Drawer for small screens ===
        drawer: useDrawer
            ? Drawer(
                width: ResponsiveHelper.getSidebarWidth(context),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final user = context.read<AuthCubit>().currentUser;
                      return SidebarWidget(
                        selectedIndex: _selectedIndex,
                        onItemSelected: (index) {
                          setState(() => _selectedIndex = index);
                          Navigator.pop(context); // Close drawer after selection
                        },
                        userName: user?.name ?? 'مستخدم',
                        userId: user?.id ?? '',
                        userRole: user?.role.value ?? 'nurse',
                        userRoleLabel: user?.role.label ?? 'ممرض',
                      );
                    },
                  ),
                )
              : null,
          body: Row(
            children: [
              // === الشريط الجانبي - Sidebar (desktop only) ===
              if (!useDrawer)
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final user = context.read<AuthCubit>().currentUser;
                    return SidebarWidget(
                      selectedIndex: _selectedIndex,
                      onItemSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      userName: user?.name ?? 'مستخدم',
                      userId: user?.id ?? '',
                      userRole: user?.role.value ?? 'nurse',
                      userRoleLabel: user?.role.label ?? 'ممرض',
                    );
                  },
                ),

            // === المحتوى الرئيسي - Main Content ===
            Expanded(
              child: Column(
                children: [
                  // === شريط التطبيق للشاشات الصغيرة ===
                  if (useDrawer)
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: const BoxDecoration(
                        gradient: AppColors.sidebarGradient,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            icon: const Icon(
                              Icons.menu_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'نيو كير',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // === محتوى الصفحة ===
                  Expanded(
                    child: Container(
                      color: AppColors.background,
                      child: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final user = context.read<AuthCubit>().currentUser;
                          final role = user?.role.value ?? 'nurse';
                          final screens = _getAvailableScreens(role);

                          return IndexedStack(
                            index: _selectedIndex < screens.length ? _selectedIndex : 0,
                            children: screens,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
