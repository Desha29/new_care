import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/user_model.dart';
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
  final _searchController = TextEditingController(); // البحث عن المستخدمين
  bool _obscurePassword = true;
  bool _isQuickLogin = true; // الوضع الافتراضي الجديد هى البطاقات
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoadingUsers = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animController.forward();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await FirebaseService.instance.getAllUsers();
      debugPrint('[Login] Fetched ${users.length} users for quick login');
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('[Login] Error fetching users: $e');
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers
          .where((u) => u.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

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
        body: isSmallScreen
            ? _buildMobileLayout()
            : _buildDesktopLayout(isTablet),
      ),
    );
  }

  /// === تخطيط الموبايل - Mobile Layout (stacked) ===
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // === البانر العلوي (مصغر) ===
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1B558E),
                  Color(0xFF103E6F),
                  Color(0xFF0A294A),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildStaggeredItem(
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: const Image(
                            image: AssetImage('assets/images/logo.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    0,
                  ),

                  _buildStaggeredItem(
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    1,
                  ),
                  const SizedBox(height: 16),
                  _buildStaggeredItem(
                    Text(
                      'الخدمات الطبية والتمريضية المتطورة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    2,
                  ),
                ],
              ),
            ),
          ),

          // === نموذج تسجيل الدخول ===
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildLoginForm(maxWidth: double.infinity),
          ),
        ],
      ),
    );
  }

  /// === تخطيط سطح المكتب - Desktop Layout (side by side) ===
  Widget _buildDesktopLayout(bool isTablet) {
    return Row(
      children: [
        // === الجانب الأيمن (نموذج الدخول) ===
        Expanded(
          flex: isTablet ? 5 : 4,
          child: Container(
            color: AppColors.background,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildLoginForm(maxWidth: isTablet ? 380 : 420),
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
                  Color(0xFF1B558E),
                  Color(0xFF103E6F),
                  Color(0xFF0A294A),
                ],
              ),
            ),
            child: Stack(
              children: [
                // === الأشكال الهندسية (Geometric Patterns) ===
                Positioned(
                  top: 40,
                  left: -50,
                  child: _buildGeometricShape(180, 0.15, rotation: 0.8),
                ),
                Positioned(
                  top: 220,
                  left: 60,
                  child: _buildGeometricShape(120, 0.1, rotation: 0.8),
                ),
                Positioned(
                  bottom: 100,
                  left: -20,
                  child: _buildGeometricShape(150, 0.12, rotation: 0.8),
                ),
                Positioned(
                  top: -40,
                  right: 40,
                  child: _buildGeometricShape(140, 0.08, rotation: 0.8),
                ),

                // === المحتوى (Content) ===
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStaggeredItem(
                          Hero(
                            tag: 'app_logo',
                            child: Container(
                              width: isTablet ? 100 : 150,
                              height: isTablet ? 100 : 150,
                              padding: EdgeInsets.all(isTablet ? 10 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 30 : 45,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 40,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 20 : 30,
                                ),
                                child: const Image(
                                  image: AssetImage('assets/images/logo.png'),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          0,
                        ),
                        const SizedBox(height: 8),
                        _buildStaggeredItem(
                          Text(
                            AppStrings.appName,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: isTablet ? 36 : 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                          1,
                        ),
                        const SizedBox(height: 16),
                        _buildStaggeredItem(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF4D03F,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFFF4D03F,
                                ).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              'الخدمات الطبية والتمريضية المتطورة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: isTablet ? 11 : 13,
                                color: const Color(0xFFF4D03F),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          2,
                        ),
                        if (!isTablet) ...[
                          const SizedBox(height: 54),
                          _buildStaggeredItem(
                            Column(children: _buildFeatureList()),
                            3,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // === شعار "صحتك أمانة" (Bottom Left Text) ===
                if (!isTablet)
                  Positioned(
                    bottom: 40,
                    left: 40,
                    child: _buildStaggeredItem(
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'صحتك',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'أمانة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF4D03F),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      4,
                    ),
                  ),

                // === أيقونة توضيحية (Bottom Right Illustration) ===
                Positioned(
                  bottom: 30,
                  right: 30,
                  child: Opacity(
                    opacity: 0.15,
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: isTablet ? 60 : 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// === نموذج تسجيل الدخول - Login Form ===
  Widget _buildLoginForm({required double maxWidth}) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
      ),
      padding: EdgeInsets.all(maxWidth == double.infinity ? 24 : 40),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStaggeredItem(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _isQuickLogin ? 'دخول سريع' : AppStrings.loginWelcome,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _isQuickLogin = !_isQuickLogin),
                  icon: Icon(_isQuickLogin ? Icons.keyboard_rounded : Icons.grid_view_rounded, size: 18),
                  label: Text(
                    _isQuickLogin ? 'تقليدي' : 'بالبطاقات',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                ),
              ],
            ),
            0,
          ),
          const SizedBox(height: 20),
          if (_isQuickLogin)
            _buildQuickLoginView()
          else
            _buildStandardLoginForm(),
        ],
      ),
    );
  }

  Widget _buildQuickLoginView() {
    if (_isLoadingUsers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_allUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'لا يمكن تحميل قائمة المستخدمين',
              style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _fetchUsers,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('لم يتم العثور على مستخدم', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return _HoverUserCard(
      user: user,
      onTap: () => _showPasswordDialog(user),
    );
  }

  void _showPasswordDialog(UserModel user) {
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, dialogSetState) {
          final authCubit = context.read<AuthCubit>();
          
          void doLogin() {
            if (passwordCtrl.text.isNotEmpty) {
              Navigator.pop(ctx);
              authCubit.login(user.email, passwordCtrl.text);
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: user.role.isAdmin ? AppColors.primary : AppColors.secondary,
                  child: const Icon(Icons.lock_person_rounded, color: Colors.white, size: 35),
                ),
                const SizedBox(height: 16),
                const Text('كلمة المرور لـ', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                Text(
                  user.name,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => doLogin(),
                  style: const TextStyle(fontFamily: 'Cairo', letterSpacing: 5),
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => dialogSetState(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
              ),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return ElevatedButton(
                    onPressed: isLoading ? null : doLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isLoading
                        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('دخول', style: TextStyle(fontFamily: 'Cairo')),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStandardLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          AppStrings.loginButton,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
            4,
          ),
        ],
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
      suffixStyle: const TextStyle(
        color: AppColors.textHint,
        fontFamily: 'Cairo',
        fontSize: 12,
      ),
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
      {
        'icon': Icons.people_outline_rounded,
        'title': 'إدارة رقمية',
        'text': 'تنظيم وإدارة حالات المرضى بفعالية',
      },
      {
        'icon': Icons.inventory_2_outlined,
        'title': 'المخزون والمستلزمات',
        'text': 'متابعة دقيقة للأدوات والموارد',
      },
      {
        'icon': Icons.analytics_outlined,
        'title': 'تقارير شاملة',
        'text': 'تحليلات للأداء المالي والطبّي',
      },
      {
        'icon': Icons.picture_as_pdf_outlined,
        'title': 'فواتير احترافية',
        'text': 'إنشاء وطباعة الفواتير بضغطة زر',
      },
    ];

    return features.map((f) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SizedBox(
          width: 320,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4D03F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  f['icon'] as IconData,
                  color: const Color(0xFFF4D03F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f['title'] as String,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f['text'] as String,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final fullEmail = email.contains('@') ? email : '$email@newcare.com';

      context.read<AuthCubit>().login(fullEmail, _passwordController.text);
    }
  }

  Widget _buildStaggeredItem(Widget child, int index) {
    final start = index * 0.15;
    final end = (start + 0.5).clamp(0.0, 1.0);

    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    final slide = Tween<Offset>(begin: const Offset(0.0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  Widget _buildGeometricShape(
    double size,
    double opacity, {
    double rotation = 0.0,
  }) {
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

class _HoverUserCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _HoverUserCard({required this.user, required this.onTap});

  @override
  State<_HoverUserCard> createState() => _HoverUserCardState();
}

class _HoverUserCardState extends State<_HoverUserCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.user.role.isAdmin ? AppColors.primary : AppColors.secondary;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isHovered 
                ? AppColors.surface 
                : AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered ? color : AppColors.border.withValues(alpha: 0.5),
                width: _isHovered ? 2 : 1,
              ),
              boxShadow: _isHovered ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'avatar_${widget.user.id}',
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: color,
                    child: Text(
                      widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 28, 
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo'
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    widget.user.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo', 
                      fontSize: 14, 
                      fontWeight: _isHovered ? FontWeight.w800 : FontWeight.w700,
                      color: _isHovered ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.user.role.label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
