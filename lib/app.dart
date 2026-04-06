import 'package:flutter/material.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/logic/cubit/auth_cubit.dart';
import 'features/auth/logic/cubit/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/main_layout.dart';

/// تطبيق نيو كير - New Care App
/// نقطة البداية الرئيسية للتطبيق مع دعم RTL واللغة العربية
class NewCareApp extends StatelessWidget {
  const NewCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()..checkAuthState()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,

        // === الثيم - Theme ===
        theme: AppTheme.lightTheme,

        // === اتجاه RTL - RTL Direction ===
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },

        // === الشاشة الرئيسية - Home Screen ===
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

/// شاشة البداية - Splash Screen
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                size: 50,
                color: Color(0xFF5AB9C1),
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
