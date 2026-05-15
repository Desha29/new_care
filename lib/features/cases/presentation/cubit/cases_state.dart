import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/case_model.dart';
import '../../../../core/enums/case_status.dart';

enum TimeFilter { today, yesterday, last7Days, thisMonth, thisYear, all, custom }

abstract class CasesState extends Equatable {
  const CasesState();
  @override
  List<Object?> get props => [];
}

class CasesInitial extends CasesState {}

class CasesLoading extends CasesState {}

class CasesLoaded extends CasesState {
  final List<CaseModel> cases;
  final String searchQuery;
  final CaseType? typeFilter;
  final String? procedureFilter; // Added for procedure filtering
  final TimeFilter timeFilter;
  final DateTime? customStartDate; // Added for custom date filtering
  final DateTime? customEndDate;   // Added for custom date filtering
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  const CasesLoaded({
    required this.cases,
    this.searchQuery = '',
    this.typeFilter,
    this.procedureFilter,
    this.timeFilter = TimeFilter.all,
    this.customStartDate,
    this.customEndDate,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDocument,
  });

  List<CaseModel> get filteredCases {
    List<CaseModel> result = cases;

    // Filter by type
    if (typeFilter != null) {
      result = result.where((c) => c.caseType == typeFilter).toList();
    }

    // Filter by procedure (service name)
    if (procedureFilter != null && procedureFilter!.isNotEmpty) {
      result = result.where((c) => c.services.any((s) => s.name == procedureFilter)).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where(
        (c) =>
            c.patientName.toLowerCase().contains(q) ||
            c.nurseName.toLowerCase().contains(q) ||
            c.patientPhone.contains(q),
      ).toList();
    }

    return result;
  }

  CasesLoaded copyWith({
    List<CaseModel>? cases,
    String? searchQuery,
    CaseType? typeFilter,
    String? procedureFilter,
    TimeFilter? timeFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    bool? isLoadingMore,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    bool clearTypeFilter = false,
    bool clearProcedureFilter = false,
  }) {
    return CasesLoaded(
      cases: cases ?? this.cases,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      procedureFilter: clearProcedureFilter ? null : (procedureFilter ?? this.procedureFilter),
      timeFilter: timeFilter ?? this.timeFilter,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }

  @override
  List<Object?> get props => [
    cases, 
    searchQuery, 
    typeFilter, 
    procedureFilter,
    timeFilter, 
    customStartDate,
    customEndDate,
    isLoadingMore, 
    hasMore, 
    lastDocument
  ];
}

class CasesError extends CasesState {
  final String message;
  const CasesError(this.message);
  @override
  List<Object?> get props => [message];
}
