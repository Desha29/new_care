import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../auth/data/models/user_model.dart';

class UsersTable extends StatelessWidget {
  final List<UserModel> users;
  final Function(UserModel) onEdit;
  final Function(UserModel) onResetPassword;
  final Function(UserModel) onToggleStatus;
  final Function(UserModel) onDelete;

  const UsersTable({
    super.key,
    required this.users,
    required this.onEdit,
    required this.onResetPassword,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = constraints.maxWidth < 800 ? 800.0 : constraints.maxWidth;
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minWidth,
                  child: Container(
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
                        _hc('المرتب', 2),
                        _hc('الحالة', 1),
                        _hc('إجراءات', 2),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: users.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.people_rounded,
                        title: 'لا يوجد مستخدمين',
                        subtitle: 'أضف مستخدمين جدد لإدارة النظام',
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: minWidth,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: users.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: AppColors.borderLight),
                            itemBuilder: (_, i) {
                              final u = users[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        color: i.isEven
                            ? Colors.transparent
                            : AppColors.surfaceVariant.withOpacity(0.3),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
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
                                overflow: TextOverflow.ellipsis,
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
                              flex: 2,
                              child: Text(
                                u.role == UserRole.nurse
                                    ? NumberFormatter.currency(u.salary)
                                    : '-',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  fontWeight: u.role == UserRole.nurse ? FontWeight.w600 : FontWeight.w400,
                                  color: u.role == UserRole.nurse ? AppColors.primary : AppColors.textHint,
                                ),
                              ),
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
                                    () => onEdit(u),
                                  ),
                                  const SizedBox(width: 4),
                                  _ab(
                                    Icons.key_rounded,
                                    AppColors.info,
                                    'إرسال رابط إعادة تعيين كلمة المرور',
                                    () => onResetPassword(u),
                                  ),
                                  const SizedBox(width: 4),
                                  _ab(
                                    u.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                                    u.isActive ? AppColors.error : AppColors.success,
                                    u.isActive ? 'تعطيل' : 'تفعيل',
                                    () => onToggleStatus(u),
                                  ),
                                  const SizedBox(width: 4),
                                  _ab(
                                    u.role == UserRole.superAdmin
                                        ? Icons.lock_outline_rounded
                                        : Icons.delete_outline_rounded,
                                    u.role == UserRole.superAdmin
                                        ? AppColors.textHint
                                        : AppColors.error,
                                    'حذف',
                                    u.role == UserRole.superAdmin ? null : () => onDelete(u),
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
              ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hc(String t, int f) => Expanded(
        flex: f,
        child: Text(t, style: AppTypography.tableHeader.copyWith(fontSize: 13)),
      );

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
}

