/// أدوار الورديات اليومية - Daily Shift Roles
enum ShiftRole {
  cases('cases', 'حالات'),
  inventory('inventory', 'مخزون'),
  externalVisits('external', 'زيارات خارجية'),
  all('all', 'جميع المهام');

  final String value;
  final String label;
  const ShiftRole(this.value, this.label);

  static ShiftRole fromString(String value) {
    return ShiftRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => ShiftRole.cases,
    );
  }
}

/// حالة الحضور - Attendance Status
enum AttendanceStatus {
  checkedIn('checked_in', 'حاضر'),
  late('late', 'متأخر'),
  checkedOut('checked_out', 'انصرف'),
  earlyLeave('early_leave', 'انصراف مبكر'),
  absent('absent', 'غائب');

  final String value;
  final String label;
  const AttendanceStatus(this.value, this.label);

  static AttendanceStatus fromString(String value) {
    return AttendanceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AttendanceStatus.absent,
    );
  }
}
