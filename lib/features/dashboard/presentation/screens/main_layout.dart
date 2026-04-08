import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/sidebar_widget.dart';
import '../../../auth/logic/cubit/auth_cubit.dart';
import '../../../auth/logic/cubit/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'dashboard_screen.dart';
import '../../../cases/presentation/screens/cases_screen.dart';
import '../../../procedures/presentation/screens/procedures_screen.dart';
import '../../../users/presentation/screens/users_screen.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../financials/presentation/screens/financials_screen.dart';
import '../../../activity_logs/presentation/screens/logs_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../settings/presentation/screens/data_status_screen.dart';

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
  final Map<int, Widget> _screenCache = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> _getAvailableScreens(String role) {
    if (role == 'admin' || role == 'super_admin') {
      return [
        const DashboardScreen(),
        const CasesScreen(),
        const ProceduresScreen(),
        const FinancialsScreen(),
        const UsersScreen(),
        const InventoryScreen(),
        const LogsScreen(),
        const SettingsScreen(),
        const DataStatusScreen(),
      ];
    } else {
      return [
        const DashboardScreen(),
        const CasesScreen(),
        const InventoryScreen(),
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
                            icon: const Icon(Icons.menu_rounded,
                                color: Colors.white),
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
                          final user =
                              context.read<AuthCubit>().currentUser;
                          final role = user?.role.value ?? 'nurse';
                          final screens = _getAvailableScreens(role);

                          if (!_screenCache.containsKey(_selectedIndex)) {
                            _screenCache[_selectedIndex] = screens[
                                _selectedIndex < screens.length
                                    ? _selectedIndex
                                    : 0];
                          }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _screenCache[_selectedIndex],
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
