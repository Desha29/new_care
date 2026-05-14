import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && widget.state is AttendanceLoaded) {
      final loadedState = widget.state as AttendanceLoaded;
      if (loadedState.hasMore && !loadedState.isLoadingMore) {
        context.read<AttendanceCubit>().loadMoreAttendance();
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    List<AttendanceModel> records = [];
    bool isLoadingMore = false;
    
    if (widget.state is AttendanceLoaded) {
      final loadedState = widget.state as AttendanceLoaded;
      records = loadedState.filteredRecords;
      isLoadingMore = loadedState.isLoadingMore;
    }

    if (widget.state is AttendanceLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (records.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.fingerprint_rounded,
        title: 'لا توجد سجلات حضور',
        subtitle: 'سيتم عرض سجلات الحضور هنا عند تسجيلها',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: isLoadingMore ? records.length + 1 : records.length,
      itemBuilder: (context, index) {
        if (index >= records.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _attendanceCard(context, records[index]);
      },
    );
  }

  Widget _attendanceCard(BuildContext context, AttendanceModel record) {
    final checkInTime = DateFormat('hh:mm a', 'ar').format(record.checkInTime);
    final checkOutTime = record.checkOutTime != null
        ? DateFormat('hh:mm a', 'ar').format(record.checkOutTime!)
        : '---';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Status Indicator Bar
              Container(
                width: 6,
                color: record.isCheckedOut ? AppColors.error : AppColors.success,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.person_rounded, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.userName,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'بتاريخ: ${record.date}',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (record.isCheckedOut ? AppColors.error : AppColors.success)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              record.status.label,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: record.isCheckedOut ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _infoItem(Icons.login_rounded, 'وقت الحضور', checkInTime, AppColors.success),
                          _infoItem(Icons.logout_rounded, 'وقت الانصراف', checkOutTime, 
                              record.isCheckedOut ? AppColors.error : AppColors.textHint),
                          _infoItem(Icons.devices_rounded, 'الجهاز المستخدم', 
                              record.deviceId.length > 10 ? '${record.deviceId.substring(0, 10)}...' : record.deviceId,
                              AppColors.primary),
                          if (record.isCheckedIn && !record.isCheckedOut)
                            IconButton(
                              onPressed: () => context.read<AttendanceCubit>().checkOut(
                                userId: record.userId,
                                userName: record.userName,
                              ),
                              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                              tooltip: 'تسجيل انصراف يدوي',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

