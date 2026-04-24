import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/network/connectivity_service.dart';
import '../../../../core/services/local/local_log_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/users_header.dart';
import '../widgets/users_stats_grid.dart';
import '../widgets/users_table.dart';
import '../widgets/user_form_dialog.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _showUserDialog({UserModel? user}) {
    UserFormDialog.show(
      context,
      user: user,
      onSaved: _loadUsers,
    );
  }

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

  Future<void> _confirmDeleteUser(UserModel u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستخدم', style: TextStyle(fontFamily: 'Cairo')),
        content: Text(
          'هل أنت متأكد من حذف ${u.name}؟ لا يمكن التراجع عن هذا الإجراء.',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
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
        _loadUsers();
        if (mounted) {
          UIFeedback.showSuccess(context, 'تم حذف المستخدم بنجاح');
        }
      } catch (e) {
        if (mounted) {
          UIFeedback.showError(context, 'خطأ في الحذف: ${e.toString()}');
        }
      }
    }
  }

  void _toggleUserStatus(UserModel user) async {
    final newStatus = !user.isActive;
    final updatedUser = user.copyWith(
      isActive: newStatus,
      updatedAt: DateTime.now(),
    );

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
        UIFeedback.showSuccess(context, 'تم ${newStatus ? 'تفعيل' : 'تعطيل'} الحساب');
      }
    } catch (e) {
      if (mounted) {
        UIFeedback.showError(context, 'حدث خطأ: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getScreenPadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isOffline) _buildOfflineBanner(),
                  UsersHeader(
                    onRefresh: _loadUsers,
                    onAddUser: () => _showUserDialog(),
                    searchController: _searchController,
                    onSearchChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 20),
                  UsersStatsGrid(users: _users),
                  const SizedBox(height: 20),
                  Expanded(
                    child: UsersTable(
                      users: _filtered,
                      onEdit: (u) => _showUserDialog(user: u),
                      onResetPassword: _resetPassword,
                      onToggleStatus: _toggleUserStatus,
                      onDelete: _confirmDeleteUser,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
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
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadConnectionStatus,
            child: const Text('تحديث', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
