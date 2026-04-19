import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/utils/validators.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/local_log_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/logic/cubit/auth_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
 
  bool _isOffline = false;
  bool _isLoading = true;
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _loadConnectionStatus();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final items = await FirebaseService.instance.getAllUsers();
      if (mounted) {
        setState(() {
          _users = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadConnectionStatus() async {
    final isConnected = await ConnectivityService.instance.checkConnection();
    if (mounted) setState(() => _isOffline = !isConnected);
  }


  List<UserModel> get _filtered {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.phone.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Builder(
        builder: (context) {
          return Padding(
            padding: EdgeInsets.all(ResponsiveHelper.getScreenPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isOffline)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: AppColors.error),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              AppStrings.offlineMode,
                              style: TextStyle(fontFamily: 'Cairo', color: AppColors.error, fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadConnectionStatus,
                            child: const Text('تحديث', style: TextStyle(fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                    ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.users,
                                style: AppTypography.pageTitle.copyWith(
                                  fontSize: ResponsiveHelper.getTitleFontSize(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(onPressed: _loadUsers, icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20)),
                            ],
                          ),
                          Text(
                            'إدارة حسابات المستخدمين والصلاحيات',
                            style: AppTypography.pageSubtitle.copyWith(
                              fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!ResponsiveHelper.isMobile(context))
                      SearchBarWidget(
                        hintText: AppStrings.searchUsers,
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    const SizedBox(width: 12),
                    PrimaryButton(
                      label: ResponsiveHelper.isMobile(context) ? 'إضافة' : AppStrings.addUser,
                      icon: Icons.person_add_rounded,
                      onPressed: () => _showUserDialog(),
                    ),
                  ],
                ),
                if (ResponsiveHelper.isMobile(context)) ...[
                  const SizedBox(height: 12),
                  SearchBarWidget(
                    hintText: AppStrings.searchUsers,
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ],
                const SizedBox(height: 20),
                // Stats cards
                GridView.count(
                  crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: ResponsiveHelper.isMobile(context) ? 2.0 : 2.5,
                  children: [
                    _statCard(
                      'إجمالي المستخدمين',
                      '${_users.length}',
                      Icons.people_rounded,
                      AppColors.primary,
                    ),
                    _statCard(
                      'الممرضون',
                      '${_users.where((u) => u.role == UserRole.nurse).length}',
                      Icons.medical_services_rounded,
                      AppColors.secondary,
                    ),
                    _statCard(
                      'المشرفون',
                      '${_users.where((u) => u.role == UserRole.admin).length}',
                      Icons.admin_panel_settings_rounded,
                      const Color(0xFF8B5CF6),
                    ),
                    _statCard(
                      'نشط',
                      '${_users.where((u) => u.isActive).length}',
                      Icons.check_circle_rounded,
                      AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildTable()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _hc('الاسم', 2),
                _hc('البريد', 2),
                _hc('الهاتف', 2),
                _hc('الصلاحية', 2),
                _hc('الحالة', 1),
                _hc('إجراءات', 2),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.people_rounded,
                    title: 'لا يوجد مستخدمين',
                    subtitle: 'أضف مستخدمين جدد لإدارة النظام',
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (_, i) {
                      final u = _filtered[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        color: i.isEven
                            ? Colors.transparent
                            : AppColors.surfaceVariant.withValues(alpha: 0.3),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: Text(
                                      u.name.isNotEmpty ? u.name.substring(0, 1) : '?',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      u.name,
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                u.email,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                u.phone,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: RoleBadge(role: u.role.name, fontSize: 11),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: u.isActive
                                      ? AppColors.statusCompletedBg
                                      : AppColors.statusCancelledBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  u.isActive ? 'نشط' : 'معطل',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: u.isActive
                                        ? AppColors.statusCompleted
                                        : AppColors.statusCancelled,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  _ab(
                                    Icons.edit_rounded,
                                    AppColors.warning,
                                    'تعديل',
                                    () => _showUserDialog(user: u),
                                  ),
                                  const SizedBox(width: 4),
                                  _ab(
                                    Icons.key_rounded,
                                    AppColors.info,
                                    'إرسال رابط إعادة تعيين كلمة المرور',
                                    () => _resetPassword(u),
                                  ),
                                  const SizedBox(width: 4),
                                  _ab(
                                    u.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                                    u.isActive ? AppColors.error : AppColors.success,
                                    u.isActive ? 'تعطيل' : 'تفعيل',
                                    () => _toggleUserStatus(u),
                                  ),
                                  const SizedBox(width: 4),
                                  _ab(
                                    u.role == UserRole.superAdmin ? Icons.lock_outline_rounded : Icons.delete_outline_rounded,
                                    u.role == UserRole.superAdmin ? AppColors.textHint : AppColors.error,
                                    'حذف',
                                    u.role == UserRole.superAdmin ? null : () => _confirmDeleteUser(u),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  Widget _ab(IconData icon, Color color, String tooltip, VoidCallback? onTap) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 18),
      ),
    ),
  );

  void _resetPassword(UserModel u) async {
    final confirm = await UIFeedback.showConfirmDialog(
      context: context,
      title: 'إعادة تعيين كلمة المرور',
      message: 'هل تريد إرسال رابط إعادة تعيين كلمة المرور إلى ${u.email}؟',
      confirmLabel: 'إرسال',
    );
    
    if (confirm && mounted) {
      try {
        await context.read<AuthCubit>().resetUserPassword(u.email);
        if (mounted) {
          UIFeedback.showSuccess(context, 'تم إرسال رابط إعادة التعيين بنجاح');
        }
      } catch (e) {
        if (mounted) {
          UIFeedback.showError(context, e.toString());
        }
      }
    }
  }

  Widget _hc(String t, int f) => Expanded(
    flex: f,
    child: Text(t, style: AppTypography.tableHeader.copyWith(fontSize: 13)),
  );

  Future<void> _confirmDeleteUser(UserModel u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستخدم', style: TextStyle(fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد من حذف ${u.name}؟ لا يمكن التراجع عن هذا الإجراء.', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseService.instance.deleteUser(u.id);
        await LocalLogService.instance.logActivity(
          userId: context.read<AuthCubit>().currentUser?.id ?? '',
          userName: context.read<AuthCubit>().currentUser?.name ?? '',
          action: 'delete_user',
          actionLabel: 'حذف مستخدم',
          details: 'تم حذف المستخدم ${u.name}',
        );
        if (mounted) {
          Navigator.pop(context); // Close dialog
          _loadUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المستخدم بنجاح', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الحذف: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _toggleUserStatus(UserModel user) async {
    final newStatus = !user.isActive;
    final updatedUser = user.copyWith(isActive: newStatus, updatedAt: DateTime.now());
    
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final uName = FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم';
      await FirebaseService.instance.updateUser(updatedUser);
      await LocalLogService.instance.logActivity(
        userId: uid,
        userName: uName,
        action: 'toggle_user_status',
        actionLabel: newStatus ? 'تفعيل مستخدم' : 'تعطيل مستخدم',
        targetType: 'user',
        targetId: updatedUser.id,
        details: 'تم ${newStatus ? "تفعيل" : "تعطيل"} حساب المستخدم: ${updatedUser.name}',
      );
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم ${newStatus ? 'تفعيل' : 'تعطيل'} الحساب', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
    
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showUserDialog({UserModel? user}) {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final passCtrl = TextEditingController();
    UserRole role = user?.role ?? UserRole.nurse;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            child: isSaving ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())) : Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEdit ? AppStrings.editUser : AppStrings.addUser,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _field('الاسم', nameCtrl, Icons.person_rounded, isRequired: true),
                    const SizedBox(height: 12),
                    _field(
                      'اسم المستخدم (للبريد)',
                      emailCtrl,
                      Icons.alternate_email_rounded,
                      dir: TextDirection.ltr,
                      isRequired: true,
                      suffixText: '@newcare.com',
                      hint: 'مثال: ahmed',
                    ),
                    const SizedBox(height: 12),
                    if (!isEdit)
                    _field(
                      'كلمة المرور',
                      passCtrl,
                      Icons.lock_rounded,
                      dir: TextDirection.ltr,
                      isRequired: true,
                    ),
                    if (!isEdit) const SizedBox(height: 12),
                    _field(
                      'رقم الهاتف',
                      phoneCtrl,
                      Icons.phone_rounded,
                      dir: TextDirection.ltr,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'الصلاحية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _roleChip('ممرض', UserRole.nurse, role, (v) => ss(() => role = v)),
                        const SizedBox(width: 8),
                        _roleChip('مشرف', UserRole.admin, role, (v) => ss(() => role = v)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              AppStrings.cancel,
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState?.validate() ?? false) {
                                ss(() => isSaving = true);
                                try {
                                  if (isEdit) {
                                    final updatedUser = user.copyWith(
                                      name: nameCtrl.text.trim(),
                                      email: emailCtrl.text.trim().contains('@') ? emailCtrl.text.trim() : '${emailCtrl.text.trim()}@newcare.com',
                                      phone: phoneCtrl.text.trim(),
                                      role: role,
                                      updatedAt: DateTime.now(),
                                    );
                                    await FirebaseService.instance.updateUser(updatedUser);
                                  } else {
                                    // 1. إنشاء الحساب في Firebase Authentication أولاً
                                    final email = emailCtrl.text.trim().contains('@') 
                                        ? emailCtrl.text.trim() 
                                        : '${emailCtrl.text.trim()}@newcare.com';
                                    
                                    final uid = await FirebaseService.instance.registerUserAuth(
                                      email, 
                                      passCtrl.text.trim()
                                    );

                                    // 2. حفظ البيانات الإضافية في Firestore باستخدام الـ UID الحقيقي
                                    final newUser = UserModel(
                                      id: uid,
                                      name: nameCtrl.text.trim(),
                                      email: email,
                                      phone: phoneCtrl.text.trim(),
                                      role: role,
                                      isActive: true,
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    );
                                    await FirebaseService.instance.createUser(newUser);
                                  }
                                  
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    _loadUsers();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEdit
                                              ? 'تم تحديث بيانات المستخدم بنجاح'
                                              : 'تم إضافة المستخدم بنجاح',
                                          style: const TextStyle(fontFamily: 'Cairo'),
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ss(() => isSaving = false);
                                  UIFeedback.showError(context, 'خطأ: ${e.toString()}');
                                }
                              }
                            },
                            child: Text(
                              AppStrings.save,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextDirection? dir,
    bool isRequired = false,
    String? suffixText,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired) const Text(' *', style: TextStyle(color: AppColors.error, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          textDirection: dir,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          validator: isRequired ? Validators.required : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
            suffixText: suffixText,
            suffixStyle: const TextStyle(color: AppColors.textHint, fontFamily: 'Cairo', fontSize: 12),
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _roleChip(
    String label,
    UserRole value,
    UserRole sel,
    Function(UserRole) fn,
  ) {
    final s = sel == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => fn(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: s
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: s ? AppColors.primary : AppColors.border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: s ? FontWeight.w600 : FontWeight.w400,
                color: s ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
