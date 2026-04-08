import 'package:equatable/equatable.dart';
import '../../data/models/attendance_model.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();
  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final List<AttendanceModel> records;
  final AttendanceModel? todayRecord; // سجل اليوم للمستخدم الحالي
  final bool isCheckedIn;

  const AttendanceLoaded({
    required this.records,
    this.todayRecord,
    this.isCheckedIn = false,
  });

  @override
  List<Object?> get props => [records, todayRecord, isCheckedIn];
}

class AttendanceCheckedIn extends AttendanceState {
  final AttendanceModel record;
  const AttendanceCheckedIn(this.record);
  @override
  List<Object?> get props => [record];
}

class AttendanceCheckedOut extends AttendanceState {
  final AttendanceModel record;
  const AttendanceCheckedOut(this.record);
  @override
  List<Object?> get props => [record];
}

class AttendanceError extends AttendanceState {
  final String message;
  const AttendanceError(this.message);
  @override
  List<Object?> get props => [message];
}

/// حالة التحقق من الوصول - Access verification result
class AccessVerificationResult extends AttendanceState {
  final bool hasShift;
  final bool isCheckedIn;
  final bool isCorrectDevice;
  final bool isGranted;
  final String message;

  const AccessVerificationResult({
    required this.hasShift,
    required this.isCheckedIn,
    required this.isCorrectDevice,
    required this.isGranted,
    this.message = '',
  });

  @override
  List<Object?> get props => [hasShift, isCheckedIn, isCorrectDevice, isGranted, message];
}
