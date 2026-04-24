import 'package:equatable/equatable.dart';
import 'package:new_care/core/enums/user_role.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final String deviceId; // معرف الجهاز الحالي
  final List<String> allowedDeviceIds; // الأجهزة المسموح بها
  final double salary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = UserRole.nurse,
    this.isActive = true,
    this.deviceId = '',
    this.allowedDeviceIds = const [],
    this.salary = 3000.0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// من Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.fromString(map['role'] ?? 'nurse'),
      isActive: map['isActive'] is int
          ? (map['isActive'] as int) == 1
          : (map['isActive'] ?? true),
      deviceId: map['deviceId'] ?? '',
      allowedDeviceIds: List<String>.from(map['allowedDeviceIds'] ?? []),
      salary: (map['salary'] ?? 3000.0).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// إلى Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'isActive': isActive,
      'deviceId': deviceId,
      'allowedDeviceIds': allowedDeviceIds,
      'salary': salary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// إلى SQLite Map
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'isActive': isActive ? 1 : 0,
      'deviceId': deviceId,
      'salary': salary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// من SQLite Map
  factory UserModel.fromSqliteMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.fromString(map['role'] ?? 'nurse'),
      isActive: (map['isActive'] ?? 1) == 1,
      deviceId: map['deviceId'] ?? '',
      salary: (map['salary'] ?? 3000.0).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    bool? isActive,
    String? deviceId,
    List<String>? allowedDeviceIds,
    double? salary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      deviceId: deviceId ?? this.deviceId,
      allowedDeviceIds: allowedDeviceIds ?? this.allowedDeviceIds,
      salary: salary ?? this.salary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    role,
    isActive,
    deviceId,
    allowedDeviceIds,
    salary,
    createdAt,
    updatedAt,
  ];
}
