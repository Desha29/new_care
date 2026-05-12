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
  final AttendanceModel? todayRecord;
  final bool isCheckedIn;
  final String searchQuery;
  final DateTime? dateFilter;

  const AttendanceLoaded({
    required this.records,
    this.todayRecord,
    this.isCheckedIn = false,
    this.searchQuery = '',
    this.dateFilter,
  });

  AttendanceLoaded copyWith({
    List<AttendanceModel>? records,
    AttendanceModel? todayRecord,
    bool? isCheckedIn,
    String? searchQuery,
    DateTime? dateFilter,
    bool clearDateFilter = false,
  }) {
    return AttendanceLoaded(
      records: records ?? this.records,
      todayRecord: todayRecord ?? this.todayRecord,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      searchQuery: searchQuery ?? this.searchQuery,
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
    );
  }

  List<AttendanceModel> get filteredRecords {
    List<AttendanceModel> result = records;

    // Filter by date
    if (dateFilter != null) {
      final dateStr = '${dateFilter!.year}-${dateFilter!.month.toString().padLeft(2, '0')}-${dateFilter!.day.toString().padLeft(2, '0')}';
      result = result.where((r) => r.date == dateStr).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((r) => r.userName.toLowerCase().contains(q)).toList();
    }

    return result;
  }

  @override
  List<Object?> get props => [records, todayRecord, isCheckedIn, searchQuery, dateFilter];
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
