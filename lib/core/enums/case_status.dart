import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// حالات الملفات الطبية - Case Status
enum CaseStatus {
  pending('pending', 'معلقة'),
  inProgress('in_progress', 'جاري التنفيذ'),
  completed('completed', 'منتهية'),
  cancelled('cancelled', 'ملغية');

  final String value;
  final String label;
  const CaseStatus(this.value, this.label);

  /// تحويل من نص إلى CaseStatus
  static CaseStatus fromString(String value) {
    return CaseStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CaseStatus.pending,
    );
  }

  /// لون الحالة
  Color get color {
    switch (this) {
      case CaseStatus.pending:
        return AppColors.statusPending;
      case CaseStatus.inProgress:
        return AppColors.statusInProgress;
      case CaseStatus.completed:
        return AppColors.statusCompleted;
      case CaseStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  /// لون خلفية الحالة
  Color get backgroundColor {
    switch (this) {
      case CaseStatus.pending:
        return AppColors.statusPendingBg;
      case CaseStatus.inProgress:
        return AppColors.statusInProgressBg;
      case CaseStatus.completed:
        return AppColors.statusCompletedBg;
      case CaseStatus.cancelled:
        return AppColors.statusCancelledBg;
    }
  }

  /// أيقونة الحالة
  IconData get icon {
    switch (this) {
      case CaseStatus.pending:
        return Icons.schedule_rounded;
      case CaseStatus.inProgress:
        return Icons.play_circle_rounded;
      case CaseStatus.completed:
        return Icons.check_circle_rounded;
      case CaseStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }
}

/// نوع الحالة - Case Type (داخل/خارج المركز)
enum CaseType {
  inCenter('in_center', 'داخل المركز'),
  homeVisit('home_visit', 'زيارة منزلية');

  final String value;
  final String label;
  const CaseType(this.value, this.label);

  static CaseType fromString(String value) {
    return CaseType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CaseType.inCenter,
    );
  }

  IconData get icon {
    switch (this) {
      case CaseType.inCenter:
        return Icons.local_hospital_rounded;
      case CaseType.homeVisit:
        return Icons.home_rounded;
    }
  }
}
