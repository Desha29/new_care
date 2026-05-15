import 'package:equatable/equatable.dart';
import '../../../../core/enums/shift_role.dart';

/// نموذج الحضور والانصراف - Attendance Model
class AttendanceModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String date; // yyyy-MM-dd format
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String deviceId;
  final String location; // GPS or WiFi network name
  final AttendanceStatus status;
  final String notes;
  final String sessionId;
  final int delayMinutes;
  final int earlyLeaveMinutes;

  const AttendanceModel({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    this.deviceId = '',
    this.location = '',
    this.status = AttendanceStatus.checkedIn,
    this.notes = '',
    this.sessionId = '',
    this.delayMinutes = 0,
    this.earlyLeaveMinutes = 0,
  });

  /// هل تم تسجيل الحضور؟ - Is checked in?
  bool get isCheckedIn => status == AttendanceStatus.checkedIn || status == AttendanceStatus.late;

  /// هل تم تسجيل الانصراف؟ - Is checked out?
  bool get isCheckedOut => status == AttendanceStatus.checkedOut || status == AttendanceStatus.earlyLeave;

  /// مدة الوردية - Shift duration
  Duration? get shiftDuration {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  /// مدة الوردية بالنص - Shift duration text
  String get shiftDurationText {
    final d = shiftDuration;
    if (d == null) return 'جاري العمل...';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '$hours ساعة و $minutes دقيقة';
  }

  /// من Firestore Map
  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      date: map['date'] ?? '',
      checkInTime: DateTime.tryParse(map['checkInTime'] ?? '') ?? DateTime.now(),
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.tryParse(map['checkOutTime'])
          : null,
      deviceId: map['deviceId'] ?? '',
      location: map['location'] ?? '',
      status: AttendanceStatus.fromString(map['status'] ?? 'checked_in'),
      notes: map['notes'] ?? '',
      sessionId: map['sessionId'] ?? '',
      delayMinutes: map['delayMinutes'] ?? 0,
      earlyLeaveMinutes: map['earlyLeaveMinutes'] ?? 0,
    );
  }

  /// إلى Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'date': date,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'deviceId': deviceId,
      'location': location,
      'status': status.value,
      'notes': notes,
      'sessionId': sessionId,
      'delayMinutes': delayMinutes,
      'earlyLeaveMinutes': earlyLeaveMinutes,
    };
  }

  /// إلى SQLite Map
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      ...toMap(),
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? deviceId,
    String? location,
    AttendanceStatus? status,
    String? notes,
    String? sessionId,
    int? delayMinutes,
    int? earlyLeaveMinutes,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      deviceId: deviceId ?? this.deviceId,
      location: location ?? this.location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      sessionId: sessionId ?? this.sessionId,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      earlyLeaveMinutes: earlyLeaveMinutes ?? this.earlyLeaveMinutes,
    );
  }

  @override
  List<Object?> get props => [
    id, userId, userName, date, checkInTime, checkOutTime,
    deviceId, location, status, notes, sessionId, delayMinutes, earlyLeaveMinutes,
  ];
}
