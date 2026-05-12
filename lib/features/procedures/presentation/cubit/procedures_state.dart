import 'package:equatable/equatable.dart';
import '../../data/models/procedure_model.dart';

abstract class ProceduresState extends Equatable {
  const ProceduresState();
  @override
  List<Object?> get props => [];
}

class ProceduresInitial extends ProceduresState {}
class ProceduresLoading extends ProceduresState {}
class ProceduresLoaded extends ProceduresState {
  final List<ProcedureModel> procedures;
  final String searchQuery;

  const ProceduresLoaded({
    required this.procedures,
    this.searchQuery = '',
  });

  ProceduresLoaded copyWith({
    List<ProcedureModel>? procedures,
    String? searchQuery,
  }) {
    return ProceduresLoaded(
      procedures: procedures ?? this.procedures,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<ProcedureModel> get filteredProcedures {
    if (searchQuery.isEmpty) return procedures;
    final q = searchQuery.toLowerCase();
    return procedures.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  List<Object?> get props => [procedures, searchQuery];
}
class ProceduresError extends ProceduresState {
  final String message;
  const ProceduresError(this.message);
  @override
  List<Object?> get props => [message];
}
