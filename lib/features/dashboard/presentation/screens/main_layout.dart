import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/sidebar_widget.dart';
import '../../../auth/logic/cubit/auth_cubit.dart';
import '../../../auth/logic/cubit/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'dashboard_screen.dart';
import '../../../patients/presentation/screens/patients_screen.dart';
import '../../../cases/presentation/screens/cases_screen.dart';
import '../../../users/presentation/screens/users_screen.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../financials/presentation/screens/financials_screen.dart';
import '../../../activity_logs/presentation/screens/logs_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// التخطيط الرئيسي - Main Layout
/// يحتوي على الشريط الجانبي والمحتوى الرئيسي
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final Map<int, Widget> _screenCache = {}; // Cache to preserve screen state

  List<Widget> _getAvailableScreens(String role) {
    if (role == 'admin' || role == 'super_admin') {
      return [
        const DashboardScreen(),
        const PatientsScreen(),
        const CasesScreen(),
        const FinancialsScreen(),
        const UsersScreen(),
        const InventoryScreen(),
        const LogsScreen(),
        const SettingsScreen(),
      ];
    } else {
      // الممرض - Nurse
      return [
        const DashboardScreen(),
        const PatientsScreen(),
        const CasesScreen(),
        const InventoryScreen(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            // === الشريط الجانبي - Sidebar ===
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
              child: Container(
                color: AppColors.background,
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final user = context.read<AuthCubit>().currentUser;
                    final role = user?.role.value ?? 'nurse';
                    final screens = _getAvailableScreens(role);
                    
                    // Use cached screen or create and cache it
                    if (!_screenCache.containsKey(_selectedIndex)) {
                      _screenCache[_selectedIndex] = screens[_selectedIndex < screens.length ? _selectedIndex : 0];
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
    );
  }
}
