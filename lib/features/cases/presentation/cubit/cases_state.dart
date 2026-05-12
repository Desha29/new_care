import 'package:equatable/equatable.dart';
import '../../data/models/case_model.dart';
import '../../../../core/enums/case_status.dart';

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

  const CasesLoaded({
    required this.cases, 
    this.searchQuery = '',
    this.typeFilter,
  });

  List<CaseModel> get filteredCases {
    List<CaseModel> result = cases;

    // Filter by type
    if (typeFilter != null) {
      result = result.where((c) => c.caseType == typeFilter).toList();
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
    bool clearTypeFilter = false,
  }) {
    return CasesLoaded(
      cases: cases ?? this.cases,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
    );
  }

  @override
  List<Object?> get props => [cases, searchQuery, typeFilter];
}

class CasesError extends CasesState {
  final String message;
  const CasesError(this.message);
  @override
  List<Object?> get props => [message];
}
