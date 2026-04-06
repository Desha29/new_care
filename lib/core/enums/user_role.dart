/// أدوار المستخدمين - User Roles
enum UserRole {
  superAdmin('super_admin', 'مدير عام'),
  admin('admin', 'مشرف'),
  nurse('nurse', 'ممرض');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  /// تحويل من نص إلى UserRole
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.nurse,
    );
  }

  /// هل المستخدم مدير؟
  bool get isAdmin => this == UserRole.superAdmin || this == UserRole.admin;

  /// هل المستخدم مدير عام؟
  bool get isSuperAdmin => this == UserRole.superAdmin;
}
