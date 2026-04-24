import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../../data/models/attendance_model.dart';

class AttendanceRecordsList extends StatefulWidget {
  final AttendanceState state;

  const AttendanceRecordsList({super.key, required this.state});

  @override
  State<AttendanceRecordsList> createState() => _AttendanceRecordsListState();
}

class _AttendanceRecordsListState extends State<AttendanceRecordsList> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    List<AttendanceModel> records = [];
    if (widget.state is AttendanceLoaded) {
      records = (widget.state as AttendanceLoaded).records;
    }

    final filteredRecords = records
        .where((r) => r.userName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = constraints.maxWidth < 750 ? 750.0 : constraints.maxWidth;
          return Column(
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'سجلات حضور اليوم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 200,
                        height: 35,
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'تصفية بالاسم...',
                            hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 18),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${filteredRecords.length} سجل',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              // Table header
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minWidth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        _hc('الموظف', 3),
                        _hc('وقت الحضور', 2),
                        _hc('وقت الانصراف', 2),
                        _hc('الحالة', 2),
                        _hc('الجهاز', 2),
                        _hc('إجراء', 1),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: widget.state is AttendanceLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredRecords.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.fingerprint_rounded,
                            title: 'لا توجد سجلات حضور اليوم',
                            subtitle: 'سيتم عرض سجلات الحضور هنا عند تسجيلها',
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: minWidth,
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredRecords.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1, color: AppColors.borderLight),
                                itemBuilder: (context, i) => _recordRow(filteredRecords[i], i),
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
        child: Text(t, style: AppTypography.tableHeader.copyWith(fontSize: 12)),
      );

  Widget _recordRow(AttendanceModel record, int i) {
    final checkInTime = DateFormat('hh:mm a', 'ar').format(record.checkInTime);
    final checkOutTime = record.checkOutTime != null
        ? DateFormat('hh:mm a', 'ar').format(record.checkOutTime!)
        : '---';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven
          ? Colors.transparent
          : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    record.userName,
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
              checkInTime,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.success,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              checkOutTime,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: record.isCheckedOut ? AppColors.error : AppColors.textHint,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: record.isCheckedIn
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.textHint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                record.status.label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: record.isCheckedIn ? AppColors.success : AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              record.deviceId.length > 15
                  ? '${record.deviceId.substring(0, 15)}...'
                  : record.deviceId,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: AppColors.textHint,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: (record.isCheckedIn && !record.isCheckedOut)
                ? IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    onPressed: () => context.read<AttendanceCubit>().checkOut(
                          userId: record.userId,
                          userName: record.userName,
                        ),
                    tooltip: 'تسجيل انصراف يدوي',
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
