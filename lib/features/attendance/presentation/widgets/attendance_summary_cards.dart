import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/shift_role.dart';
import '../cubit/attendance_state.dart';

class AttendanceSummaryCards extends StatelessWidget {
  final AttendanceLoaded state;

  const AttendanceSummaryCards({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final records = state.records;
    final total = records.length;
    final present = records.where((r) => r.isCheckedIn).length;
    final late = records.where((r) => r.status == AttendanceStatus.late).length;
    final checkedOut = records.where((r) => r.isCheckedOut).length;

    return Row(
      children: [
        _buildCard(
          context,
          title: 'إجمالي الموظفين',
          value: total.toString(),
          icon: Icons.people_outline,
          color: AppColors.primary,
        ),
        const SizedBox(width: 16),
        _buildCard(
          context,
          title: 'حاضر الآن',
          value: present.toString(),
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        _buildCard(
          context,
          title: 'متأخرون',
          value: late.toString(),
          icon: Icons.access_time,
          color: Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildCard(
          context,
          title: 'انصرفوا',
          value: checkedOut.toString(),
          icon: Icons.exit_to_app,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(
            bottom: BorderSide(color: color, width: 4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
