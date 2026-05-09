import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/services/network/connectivity_service.dart';
import '../../../../core/services/notifications/data_change_notifier.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/users_cubit.dart';
import '../cubit/users_state.dart';
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
  bool _isOffline = false;
  StreamSubscription? _dataChangeSub;
  // Key to force-rebuild the BlocProvider when data changes from cloud
  Key _blocKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadConnectionStatus();

    // Listen for cloud download to auto-refresh users
    _dataChangeSub = DataChangeNotifier().onDataChanged.listen((_) {
      if (mounted) {
        setState(() => _blocKey = UniqueKey());
      }
    });
  }

  @override
  void dispose() {
    _dataChangeSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConnectionStatus() async {
    final isConnected = await ConnectivityService.instance.checkConnection();
    if (mounted) setState(() => _isOffline = !isConnected);
  }

  void _showUserDialog(BuildContext context, {UserModel? user}) {
    UserFormDialog.show(
      context,
      user: user,
      onSaved: () => context.read<UsersCubit>().loadUsers(force: true),
    );
  }

  void _resetPassword(BuildContext context, UserModel u) async {
    final confirm = await UIFeedback.showConfirmDialog(
      context: context,
      title: 'إعادة تعيين كلمة المرور',
      message: 'هل تريد إرسال رابط إعادة تعيين كلمة المرور إلى ${u.email}؟',
      confirmLabel: 'إرسال',
    );

    if (confirm && context.mounted) {
      try {
        await context.read<AuthCubit>().resetUserPassword(u.email);
        if (context.mounted) {
          UIFeedback.showSuccess(context, 'تم إرسال رابط إعادة التعيين بنجاح');
        }
      } catch (e) {
        if (context.mounted) {
          UIFeedback.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _confirmDeleteUser(BuildContext context, UserModel u) async {
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

    if (confirmed == true && context.mounted) {
      context.read<UsersCubit>().deleteUser(u.id, u.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsersCubit, UsersState>(
      listener: (context, state) {
        if (state is UsersError) {
          UIFeedback.showError(context, state.message);
        } else if (state is UserOperationSuccess) {
          UIFeedback.showSuccess(context, state.message);
          context.read<UsersCubit>().resetState();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: state is UsersLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: EdgeInsets.all(ResponsiveHelper.getScreenPadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isOffline) _buildOfflineBanner(),
                      UsersHeader(
                        onRefresh: () => context.read<UsersCubit>().loadUsers(force: true),
                        onAddUser: () => _showUserDialog(context),
                        searchController: _searchController,
                        onSearchChanged: (v) => context.read<UsersCubit>().searchUsers(v),
                      ),
                      const SizedBox(height: 20),
                      if (state is UsersLoaded) ...[
                        UsersStatsGrid(users: state.users),
                        const SizedBox(height: 20),
                        Expanded(
                          child: UsersTable(
                            users: state.filteredUsers,
                            onEdit: (u) => _showUserDialog(context, user: u),
                            onResetPassword: (u) => _resetPassword(context, u),
                            onToggleStatus: (u) => context.read<UsersCubit>().toggleUserStatus(u),
                            onDelete: (u) => _confirmDeleteUser(context, u),
                          ),
                        ),
                      ] else if (state is UsersError)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => context.read<UsersCubit>().loadUsers(force: true),
                                  child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
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

