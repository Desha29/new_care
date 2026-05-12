import 'package:equatable/equatable.dart';
import '../../data/models/inventory_model.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}
class InventoryLoading extends InventoryState {}
class InventoryLoaded extends InventoryState {
  final List<InventoryModel> items;
  final String searchQuery;
  final String? categoryFilter;

  const InventoryLoaded({
    required this.items,
    this.searchQuery = '',
    this.categoryFilter,
  });

  InventoryLoaded copyWith({
    List<InventoryModel>? items,
    String? searchQuery,
    String? categoryFilter,
    bool clearCategoryFilter = false,
  }) {
    return InventoryLoaded(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
    );
  }

  List<InventoryModel> get filteredItems {
    List<InventoryModel> result = items;

    if (categoryFilter != null) {
      result = result.where((i) => i.category == categoryFilter).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((i) => i.name.toLowerCase().contains(q)).toList();
    }

    return result;
  }

  @override
  List<Object?> get props => [items, searchQuery, categoryFilter];
}
class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
  @override
  List<Object?> get props => [message];
}
