import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/enums/shift_role.dart';
import '../../data/models/attendance_model.dart';
import '../cubit/attendance_state.dart';

class AttendanceTable extends StatelessWidget {
  final AttendanceLoaded state;
  final bool isPersonal;

  const AttendanceTable({
    super.key,
    required this.state,
    this.isPersonal = false,
  });

  @override
  Widget build(BuildContext context) {
    final records = state.filteredRecords;

    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 48, color: AppColors.textHint),
              SizedBox(height: 12),
              Text('لا يوجد سجل حضور مطابق للبحث', style: TextStyle(fontFamily: 'Cairo')),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Table header
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: minWidth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.radiusLg),
                        topRight: Radius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (!isPersonal) _hc('الموظف', 3),
                        _hc('التاريخ', 2),
                        _hc('الحالة', 2),
                        _hc('وقت الحضور', 2),
                        _hc('وقت الانصراف', 2),
                        _hc('التأخير', 1),
                        _hc('المدة', 2),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              // Table body
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minWidth,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (context, i) => _buildRow(context, records[i], i),
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
        child: Text(
          t,
          style: AppTypography.tableHeader.copyWith(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      );

  Widget _buildRow(BuildContext context, AttendanceModel record, int index) {
    final checkIn = DateFormat('hh:mm a', 'ar').format(record.checkInTime);
    final checkOut = record.checkOutTime != null
        ? DateFormat('hh:mm a', 'ar').format(record.checkOutTime!)
        : '---';

    final date = DateFormat('yyyy/MM/dd', 'ar').format(record.checkInTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          if (!isPersonal)
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      record.userName.isNotEmpty ? record.userName.substring(0, 1) : '?',
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
                      record.userName,
                      style: AppTypography.tableCell.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            flex: 2,
            child: Text(date, style: AppTypography.tableCell),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildStatusBadge(record.status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              checkIn,
              style: AppTypography.tableCell.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              checkOut,
              style: AppTypography.tableCell.copyWith(
                color: record.checkOutTime != null ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              record.delayMinutes > 0 ? '${record.delayMinutes} د' : '---',
              style: AppTypography.tableCell.copyWith(
                color: record.delayMinutes > 0 ? AppColors.error : AppColors.textHint,
                fontWeight: record.delayMinutes > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              record.shiftDurationText,
              style: AppTypography.tableCell.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AttendanceStatus status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case AttendanceStatus.checkedIn:
        bgColor = AppColors.statusCompletedBg;
        textColor = AppColors.statusCompleted;
        break;
      case AttendanceStatus.late:
        bgColor = AppColors.statusPendingBg;
        textColor = AppColors.statusPending;
        break;
      case AttendanceStatus.checkedOut:
      case AttendanceStatus.earlyLeave:
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primary;
        break;
      case AttendanceStatus.absent:
        bgColor = AppColors.statusCancelledBg;
        textColor = AppColors.statusCancelled;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
