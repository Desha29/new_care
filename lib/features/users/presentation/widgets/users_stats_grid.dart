import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/enums/user_role.dart';
import '../../../auth/data/models/user_model.dart';

class UsersStatsGrid extends StatelessWidget {
  final List<UserModel> users;

  const UsersStatsGrid({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 2.0 : 2.5,
      children: [
        _statCard(
          'إجمالي المستخدمين',
          '${users.length}',
          Icons.people_rounded,
          AppColors.primary,
        ),
        _statCard(
          'الممرضون',
          '${users.where((u) => u.role == UserRole.nurse).length}',
          Icons.medical_services_rounded,
          AppColors.secondary,
        ),
        _statCard(
          'المشرفون',
          '${users.where((u) => u.role == UserRole.admin).length}',
          Icons.admin_panel_settings_rounded,
          const Color(0xFF8B5CF6),
        ),
        _statCard(
          'نشط',
          '${users.where((u) => u.isActive).length}',
          Icons.check_circle_rounded,
          AppColors.success,
        ),
      ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
