import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/logic/connectivity_cubit.dart';
import 'core/logic/error_cubit.dart';
import 'core/di/injection.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/main_layout.dart';
import 'core/utils/ui_feedback.dart';

import 'features/cases/presentation/cubit/cases_cubit.dart';
import 'features/procedures/presentation/cubit/procedures_cubit.dart';
import 'features/inventory/presentation/cubit/inventory_cubit.dart';
import 'features/financials/presentation/cubit/financials_cubit.dart';
import 'features/shifts/presentation/cubit/shift_cubit.dart';
import 'features/attendance/presentation/cubit/attendance_cubit.dart';
import 'features/payroll/presentation/cubit/payroll_cubit.dart';
import 'features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'features/attendance/presentation/cubit/attendance_state.dart';
import 'features/users/presentation/cubit/users_cubit.dart';

class NewCareApp extends StatelessWidget {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
  
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
        BlocProvider(create: (_) => sl<PayrollCubit>()),
        BlocProvider(create: (_) => sl<DashboardCubit>()),
        BlocProvider(create: (_) => sl<UsersCubit>()..loadUsers()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        scaffoldMessengerKey: messengerKey,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', ''),
          Locale('en', ''),
        ],
        locale: const Locale('ar'),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: MultiBlocListener(
              listeners: [
                // ممع الاستماع للأخطاء - Global Error Listener
                BlocListener<ErrorCubit, GlobalErrorState>(
                  listener: (context, state) {
                    if (state.isError && state.message != null) {
                      UIFeedback.showError(context, state.message!);
                      context.read<ErrorCubit>().clearError();
                    }
                  },
                ),
                // الاستماع لاتصال الشبكة - Connectivity Listener
                BlocListener<ConnectivityCubit, ConnectivityStatus>(
                  listener: (context, status) {
                    if (status == ConnectivityStatus.offline) {
                      UIFeedback.showError(context, AppStrings.offlineMode);
                    } else {
                      UIFeedback.showInfo(context, 'أنت متصل الآن');
                    }
                  },
                ),
                // الاستماع لتسجيل الحضور والانصراف - Attendance Listener
                BlocListener<AttendanceCubit, AttendanceState>(
                  listener: (context, state) {
                    if (state is AttendanceCheckedIn) {
                      UIFeedback.showSuccess(context, 'تم تسجيل الحضور بنجاح ✅');
                    } else if (state is AttendanceCheckedOut) {
                      final record = state.record;
                      if (record.checkOutTime != null) {
                        final duration = record.checkOutTime!.difference(record.checkInTime);
                        final hours = duration.inHours;
                        final minutes = duration.inMinutes % 60;
                        
                        String durationStr = '';
                        if (hours > 0) durationStr += '$hours ساعة ';
                        if (minutes > 0) durationStr += '$minutes دقيقة';
                        if (durationStr.isEmpty) durationStr = 'أقل من دقيقة';

                        UIFeedback.showSuccess(context, 'تم تسجيل الانصراف بنجاح. مدة العمل: $durationStr ✅');
                      }
                    } else if (state is AttendanceError) {
                      UIFeedback.showError(context, state.message);
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

