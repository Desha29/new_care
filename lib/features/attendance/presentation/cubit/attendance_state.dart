import 'package:equatable/equatable.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/attendance_session_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final AttendanceSessionModel? activeSession;
  final Map<DateTime, int> stats;
  final bool isCheckedIn;
  final String searchQuery;
  final DateTime? dateFilter;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final bool isLoadingMore;
  final bool isLoadingStats;

  const AttendanceLoaded({
    required this.records,
    this.todayRecord,
    this.activeSession,
    this.stats = const {},
    this.isCheckedIn = false,
    this.searchQuery = '',
    this.dateFilter,
    this.hasMore = false,
    this.lastDocument,
    this.isLoadingMore = false,
    this.isLoadingStats = false,
  });

  AttendanceLoaded copyWith({
    List<AttendanceModel>? records,
    AttendanceModel? todayRecord,
    AttendanceSessionModel? activeSession,
    Map<DateTime, int>? stats,
    bool? isCheckedIn,
    String? searchQuery,
    DateTime? dateFilter,
    bool clearDateFilter = false,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    bool? isLoadingMore,
    bool? isLoadingStats,
    bool clearActiveSession = false,
  }) {
    return AttendanceLoaded(
      records: records ?? this.records,
      todayRecord: todayRecord ?? this.todayRecord,
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
      stats: stats ?? this.stats,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      searchQuery: searchQuery ?? this.searchQuery,
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
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
  List<Object?> get props => [
        records,
        todayRecord,
        activeSession,
        stats,
        isCheckedIn,
        searchQuery,
        dateFilter,
        hasMore,
        lastDocument,
        isLoadingMore,
        isLoadingStats,
      ];
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
