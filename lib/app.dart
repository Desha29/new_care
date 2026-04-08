import 'package:flutter/material.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/logic/connectivity_cubit.dart';
import 'core/logic/error_cubit.dart';
import 'core/di/injection.dart';
import 'features/auth/logic/cubit/auth_cubit.dart';
import 'features/auth/logic/cubit/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/main_layout.dart';

import 'features/cases/logic/cubit/cases_cubit.dart';
import 'features/procedures/logic/cubit/procedures_cubit.dart';
import 'features/inventory/logic/cubit/inventory_cubit.dart';
import 'features/financials/logic/cubit/financials_cubit.dart';
import 'features/shifts/logic/cubit/shift_cubit.dart';
import 'features/attendance/logic/cubit/attendance_cubit.dart';

class NewCareApp extends StatelessWidget {
  const NewCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthCubit>()..checkAuthState()),
        BlocProvider(create: (_) => sl<ConnectivityCubit>()),
        BlocProvider(create: (_) => sl<ErrorCubit>()),
        BlocProvider(create: (_) => sl<CasesCubit>()..loadCases()),
        BlocProvider(create: (_) => sl<ProceduresCubit>()..loadProcedures()),
        BlocProvider(create: (_) => sl<InventoryCubit>()..loadInventory()),
        BlocProvider(create: (_) => sl<FinancialsCubit>()..loadFinancials()),
        BlocProvider(create: (_) => sl<ShiftCubit>()),
        BlocProvider(create: (_) => sl<AttendanceCubit>()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: MultiBlocListener(
              listeners: [
                // ممع الاستماع للأخطاء - Global Error Listener
                BlocListener<ErrorCubit, GlobalErrorState>(
                  listener: (context, state) {
                    if (state.isError && state.message != null) {
                      _showSnackBar(context, state.message!, isError: true);
                      context.read<ErrorCubit>().clearError();
                    }
                  },
                ),
                // الاستماع لاتصال الشبكة - Connectivity Listener
                BlocListener<ConnectivityCubit, ConnectivityStatus>(
                  listener: (context, status) {
                    if (status == ConnectivityStatus.offline) {
                      _showSnackBar(context, AppStrings.offlineMode, isError: true);
                    } else {
                      _showSnackBar(context, 'أنت متصل الآن', isError: false);
                    }
                  },
                ),
              ],
              child: child!,
            ),
          );
        },
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return const MainLayout();
            }
            if (state is AuthLoading) {
              return const _SplashScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3B66),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.appSubtitle,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF5AB9C1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
