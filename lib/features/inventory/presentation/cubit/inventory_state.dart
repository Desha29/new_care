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
  const InventoryLoaded({required this.items, this.searchQuery = ''});

  List<InventoryModel> get filteredItems {
    if (searchQuery.isEmpty) return items;
    return items.where((i) => i.name.contains(searchQuery) || i.category.contains(searchQuery)).toList();
  }

  @override
  List<Object?> get props => [items, searchQuery];
}
class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
  @override
  List<Object?> get props => [message];
}
