import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// حالات المزامنة - Sync Status
enum SyncStatus {
  pending('pending', 'قيد الانتظار'),
  syncing('syncing', 'جاري المزامنة'),
  synced('synced', 'تمت المزامنة'),
  conflict('conflict', 'يوجد تعارض'),
  failed('failed', 'فشلت المزامنة');

  final String value;
  final String label;
  const SyncStatus(this.value, this.label);

  /// تحويل من نص إلى SyncStatus
  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SyncStatus.pending,
    );
  }

  /// لون الحالة - Status color
  Color get color {
    switch (this) {
      case SyncStatus.pending:
        return AppColors.statusPending;
      case SyncStatus.syncing:
        return AppColors.statusInProgress;
      case SyncStatus.synced:
        return AppColors.statusCompleted;
      case SyncStatus.conflict:
        return AppColors.warning;
      case SyncStatus.failed:
        return AppColors.error;
    }
  }

  /// أيقونة الحالة - Status icon
  IconData get icon {
    switch (this) {
      case SyncStatus.pending:
        return Icons.schedule_rounded;
      case SyncStatus.syncing:
        return Icons.sync_rounded;
      case SyncStatus.synced:
        return Icons.cloud_done_rounded;
      case SyncStatus.conflict:
        return Icons.warning_amber_rounded;
      case SyncStatus.failed:
        return Icons.cloud_off_rounded;
    }
  }
}
