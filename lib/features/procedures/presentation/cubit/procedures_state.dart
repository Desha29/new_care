import 'package:equatable/equatable.dart';
import '../../data/models/procedure_model.dart';

enum ProcedureSort { name, priceAsc, priceDesc }

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
  final ProcedureSort sortBy;
  final double? maxPrice;

  const ProceduresLoaded({
    required this.procedures,
    this.searchQuery = '',
    this.sortBy = ProcedureSort.name, // Default value provided
    this.maxPrice,
  });

  ProceduresLoaded copyWith({
    List<ProcedureModel>? procedures,
    String? searchQuery,
    ProcedureSort? sortBy,
    double? maxPrice,
    bool clearMaxPrice = false,
  }) {
    return ProceduresLoaded(
      procedures: procedures ?? this.procedures,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
    );
  }

  List<ProcedureModel> get filteredProcedures {
    List<ProcedureModel> result = List.from(procedures);

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    // Filter by price
    if (maxPrice != null) {
      result = result.where((p) => p.defaultPrice <= maxPrice!).toList();
    }

    // Sort
    // Safe-guard: even if sortBy is somehow null during hot-reload transitions
    final sort = sortBy;
    switch (sort) {
      case ProcedureSort.name:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProcedureSort.priceAsc:
        result.sort((a, b) => a.defaultPrice.compareTo(b.defaultPrice));
        break;
      case ProcedureSort.priceDesc:
        result.sort((a, b) => b.defaultPrice.compareTo(a.defaultPrice));
        break;
    }

    return result;
  }

  @override
  List<Object?> get props => [procedures, searchQuery, sortBy, maxPrice];
}

class ProceduresError extends ProceduresState {
  final String message;
  const ProceduresError(this.message);
  @override
  List<Object?> get props => [message];
}
