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
  
  const CasesLoaded({required this.cases, this.searchQuery = ''});

  List<CaseModel> get filteredCases {
    if (searchQuery.isEmpty) return cases;
    final q = searchQuery.toLowerCase();
    return cases.where((c) => 
      c.patientName.toLowerCase().contains(q) || 
      c.nurseName.toLowerCase().contains(q) ||
      c.patientPhone.contains(q)
    ).toList();
  }

  @override
  List<Object?> get props => [cases, searchQuery];
}
class CasesError extends CasesState {
  final String message;
  const CasesError(this.message);
  @override
  List<Object?> get props => [message];
}
