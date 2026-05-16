import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_utils.dart';

/// نموذج جلسة الحضور - Attendance Session Model
class AttendanceSessionModel extends Equatable {
  final String id;
  final String adminId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final String qrSecret; // Rotates every 60s
  final double latitude;
  final double longitude;
  final double radius; // in meters

  const AttendanceSessionModel({
    required this.id,
    required this.adminId,
    required this.startTime,
    this.endTime,
    this.isActive = true,
    this.qrSecret = '',
    this.latitude = 0,
    this.longitude = 0,
    this.radius = 50,
  });

  factory AttendanceSessionModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceSessionModel(
      id: id,
      adminId: map['adminId'] ?? '',
      startTime: AppDateUtils.parseDynamic(map['startTime']),
      endTime: AppDateUtils.parseDynamicNullable(map['endTime']),
      isActive: map['isActive'] ?? false,
      qrSecret: map['qrSecret'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      radius: (map['radius'] ?? 50).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isActive': isActive,
      'qrSecret': qrSecret,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }

  AttendanceSessionModel copyWith({
    String? id,
    String? adminId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
    String? qrSecret,
    double? latitude,
    double? longitude,
    double? radius,
  }) {
    return AttendanceSessionModel(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      qrSecret: qrSecret ?? this.qrSecret,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
    );
  }

  @override
  List<Object?> get props => [
    id,
    adminId,
    startTime,
    endTime,
    isActive,
    qrSecret,
    latitude,
    longitude,
    radius,
  ];
}
