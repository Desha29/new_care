/// أدوار الورديات اليومية - Daily Shift Roles
enum ShiftRole {
  cases('cases', 'حالات'),
  inventory('inventory', 'مخزون'),
  external_visits('external', 'زيارات خارجية'),
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
  checkedOut('checked_out', 'انصرف'),
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
