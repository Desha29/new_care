import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/utils/validators.dart';
import '../../logic/cubit/auth_cubit.dart';
import '../../logic/cubit/auth_state.dart';
import '../../../dashboard/presentation/screens/main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
       duration: const Duration(milliseconds: 1200),
       vsync: this,
     );
     _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainLayout()),
          );
        } else if (state is AuthError) {
          UIFeedback.showError(context, state.message);
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            // === الجانب الأيمن (نموذج الدخول) ===
            Expanded(
              flex: 4,
              child: Container(
                color: AppColors.background,
                child: Center(
                  child: Container(
                    width: 420,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStaggeredItem(
                            const Text(
                              AppStrings.loginWelcome,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            0,
                          ),
                          const SizedBox(height: 4),
                          _buildStaggeredItem(
                            const Text(
                              AppStrings.loginSubtitle,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            1,
                          ),
                          const SizedBox(height: 36),
                          _buildStaggeredItem(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(AppStrings.email),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textDirection: TextDirection.ltr,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                                  decoration: _inputDecoration(
                                    hint: 'اسم المستخدم',
                                    icon: Icons.alternate_email_rounded,
                                    suffixText: '@newcare.com',
                                  ),
                                  validator: Validators.required,
                                ),
                              ],
                            ),
                            2,
                          ),
                          const SizedBox(height: 20),
                          _buildStaggeredItem(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(AppStrings.password),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textDirection: TextDirection.ltr,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _onLogin(),
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                                  decoration: _inputDecoration(
                                    hint: '••••••••',
                                    icon: Icons.lock_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textHint, size: 20),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: Validators.password,
                                ),
                              ],
                            ),
                            3,
                          ),
                          const SizedBox(height: 32),
                          _buildStaggeredItem(
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return ElevatedButton(
                                  onPressed: isLoading ? null : _onLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text(AppStrings.loginButton, style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w600)),
                                );
                              },
                            ),
                            4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // === الجانب الأيسر (تصميم الشعار) - Side Banner ===
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B558E), // Lighter professional blue
                      Color(0xFF103E6F), // NEW Primary color #103E6F
                      Color(0xFF0A294A), // Deep navy shadow
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // === الأشكال الهندسية (Geometric Patterns) ===
                    Positioned(
                      top: 40, left: -50,
                      child: _buildGeometricShape(180, 0.15, rotation: 0.8),
                    ),
                    Positioned(
                      top: 220, left: 60,
                      child: _buildGeometricShape(120, 0.1, rotation: 0.8),
                    ),
                    Positioned(
                      bottom: 100, left: -20,
                      child: _buildGeometricShape(150, 0.12, rotation: 0.8),
                    ),
                    Positioned(
                      top: -40, right: 40,
                      child: _buildGeometricShape(140, 0.08, rotation: 0.8),
                    ),
                    
                    // === المحتوى (Content) ===
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStaggeredItem(
                            Container(
                              width: 140, height: 140, padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: const Image(image: AssetImage('assets/images/logo.png'), fit: BoxFit.contain)
                              ),
                            ),
                            0,
                          ),
                          const SizedBox(height: 32),
                          _buildStaggeredItem(
                            const Text(
                              AppStrings.appName,
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                            ),
                            1,
                          ),
                          _buildStaggeredItem(
                            Text(
                              'NEW CARE - NURSING CARE SERVES',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600, letterSpacing: 1.5),
                            ),
                            1,
                          ),
                          const SizedBox(height: 48),
                          _buildStaggeredItem(
                            Column(children: _buildFeatureList()),
                            3,
                          ),
                        ],
                      ),
                    ),

                    // === شعار "صحتك أمانة" (Bottom Left Text) ===
                    Positioned(
                      bottom: 40, left: 40,
                      child: _buildStaggeredItem(
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'صحتك',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                            ),
                            Text(
                              'أمانة',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFFF4D03F), height: 1.1),
                            ),
                          ],
                        ),
                        4,
                      ),
                    ),
                    
                    // === أيقونة توضيحية (Bottom Right Illustration) ===
                    Positioned(
                      bottom: 30, right: 30,
                      child: Opacity(
                        opacity: 0.15,
                        child: Icon(Icons.medical_services_outlined, size: 100, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.ltr,
      prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: AppColors.textHint, fontFamily: 'Cairo', fontSize: 12),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  List<Widget> _buildFeatureList() {
    final features = [
      {'icon': Icons.people_outline_rounded, 'text': 'إدارة المرضى والحالات الرقمية'},
      {'icon': Icons.inventory_2_outlined, 'text': 'متابعة المخزون والمستلزمات'},
      {'icon': Icons.analytics_outlined, 'text': 'تقارير الأداء المالي والطبّي'},
      {'icon': Icons.picture_as_pdf_outlined, 'text': 'فواتير احترافية وتقارير PDF'},
    ];

    return features.map((f) {
      return Container(
        width: 280,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                f['icon'] as IconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                f['text'] as String,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final fullEmail = email.contains('@') ? email : '$email@newcare.com';
      
      context.read<AuthCubit>().login(
        fullEmail,
        _passwordController.text,
      );
    }
  }

  Widget _buildStaggeredItem(Widget child, int index) {
    final start = index * 0.15;
    final end = (start + 0.5).clamp(0.0, 1.0);
    
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController, 
        curve: Interval(start, end, curve: Curves.easeOutCubic)
      )
    );
    
    final slide = Tween<Offset>(begin: const Offset(0.0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController, 
        curve: Interval(start, end, curve: Curves.easeOutCubic)
      )
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }

  Widget _buildGeometricShape(double size, double opacity, {double rotation = 0.0}) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(size * 0.2),
        ),
      ),
    );
  }
}
