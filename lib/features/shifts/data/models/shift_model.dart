import 'package:equatable/equatable.dart';
import '../../../../core/enums/shift_role.dart';

/// نموذج صلاحيات الوردية - Shift Permissions Model
class ShiftPermissions extends Equatable {
  final bool canAccessCases;
  final bool canAccessInventory;
  final bool canGoExternal;
  final bool canManageFinancials;

  const ShiftPermissions({
    this.canAccessCases = false,
    this.canAccessInventory = false,
    this.canGoExternal = false,
    this.canManageFinancials = false,
  });

  Map<String, dynamic> toMap() => {
    'canAccessCases': canAccessCases,
    'canAccessInventory': canAccessInventory,
    'canGoExternal': canGoExternal,
    'canManageFinancials': canManageFinancials,
  };

  factory ShiftPermissions.fromMap(Map<String, dynamic> map) {
    return ShiftPermissions(
      canAccessCases: map['canAccessCases'] ?? false,
      canAccessInventory: map['canAccessInventory'] ?? false,
      canGoExternal: map['canGoExternal'] ?? false,
      canManageFinancials: map['canManageFinancials'] ?? false,
    );
  }

  /// صلاحيات كاملة - Full permissions
  factory ShiftPermissions.full() => const ShiftPermissions(
    canAccessCases: true,
    canAccessInventory: true,
    canGoExternal: true,
    canManageFinancials: true,
  );

  /// صلاحيات حسب الدور - Permissions by role
  factory ShiftPermissions.fromRole(ShiftRole role) {
    switch (role) {
      case ShiftRole.cases:
        return const ShiftPermissions(canAccessCases: true);
      case ShiftRole.inventory:
        return const ShiftPermissions(canAccessInventory: true);
      case ShiftRole.external_visits:
        return const ShiftPermissions(canAccessCases: true, canGoExternal: true);
      case ShiftRole.all:
        return ShiftPermissions.full();
    }
  }

  ShiftPermissions copyWith({
    bool? canAccessCases,
    bool? canAccessInventory,
    bool? canGoExternal,
    bool? canManageFinancials,
  }) {
    return ShiftPermissions(
      canAccessCases: canAccessCases ?? this.canAccessCases,
      canAccessInventory: canAccessInventory ?? this.canAccessInventory,
      canGoExternal: canGoExternal ?? this.canGoExternal,
      canManageFinancials: canManageFinancials ?? this.canManageFinancials,
    );
  }

  @override
  List<Object?> get props => [canAccessCases, canAccessInventory, canGoExternal, canManageFinancials];
}

/// نموذج الوردية اليومية - Daily Shift Model
class ShiftModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String date; // yyyy-MM-dd format
  final ShiftRole roleToday;
  final ShiftPermissions permissions;
  final String notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShiftModel({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.date,
    this.roleToday = ShiftRole.cases,
    required this.permissions,
    this.notes = '',
    this.createdBy = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// من Firestore Map
  factory ShiftModel.fromMap(Map<String, dynamic> map, String id) {
    return ShiftModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      date: map['date'] ?? '',
      roleToday: ShiftRole.fromString(map['roleToday'] ?? 'cases'),
      permissions: ShiftPermissions.fromMap(
        (map['permissions'] as Map<String, dynamic>?) ?? {},
      ),
      notes: map['notes'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// إلى Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'date': date,
      'roleToday': roleToday.value,
      'permissions': permissions.toMap(),
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// إلى SQLite Map
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'date': date,
      'roleToday': roleToday.value,
      'canAccessCases': permissions.canAccessCases ? 1 : 0,
      'canAccessInventory': permissions.canAccessInventory ? 1 : 0,
      'canGoExternal': permissions.canGoExternal ? 1 : 0,
      'canManageFinancials': permissions.canManageFinancials ? 1 : 0,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ShiftModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? date,
    ShiftRole? roleToday,
    ShiftPermissions? permissions,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      roleToday: roleToday ?? this.roleToday,
      permissions: permissions ?? this.permissions,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, userName, date, roleToday, permissions, notes, createdBy, createdAt, updatedAt];
}
