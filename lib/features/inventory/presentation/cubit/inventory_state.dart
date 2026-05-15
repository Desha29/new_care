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
  final String stockFilter; // all, lowStock, outOfStock, healthy
  final String expiryFilter; // all, expiringSoon, expired

  const InventoryLoaded({
    required this.items,
    this.searchQuery = '',
    this.categoryFilter,
    this.stockFilter = 'all',
    this.expiryFilter = 'all',
  });

  InventoryLoaded copyWith({
    List<InventoryModel>? items,
    String? searchQuery,
    String? categoryFilter,
    bool clearCategoryFilter = false,
    String? stockFilter,
    String? expiryFilter,
  }) {
    return InventoryLoaded(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      stockFilter: stockFilter ?? this.stockFilter,
      expiryFilter: expiryFilter ?? this.expiryFilter,
    );
  }

  List<InventoryModel> get filteredItems {
    List<InventoryModel> result = items;

    if (categoryFilter != null) {
      result = result.where((i) => i.category == categoryFilter).toList();
    }

    if (stockFilter != 'all') {
      if (stockFilter == 'lowStock') {
        result = result.where((i) => i.isLowStock).toList();
      } else if (stockFilter == 'outOfStock') {
        result = result.where((i) => i.isOutOfStock).toList();
      } else if (stockFilter == 'healthy') {
        result = result.where((i) => !i.isLowStock && !i.isOutOfStock).toList();
      }
    }

    if (expiryFilter != 'all') {
      if (expiryFilter == 'expiringSoon') {
        result = result.where((i) => i.isExpiringSoon).toList();
      } else if (expiryFilter == 'expired') {
        result = result.where((i) => i.isExpired).toList();
      }
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((i) => i.name.toLowerCase().contains(q)).toList();
    }

    return result;
  }

  @override
  List<Object?> get props => [items, searchQuery, categoryFilter, stockFilter, expiryFilter];
}
class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
  @override
  List<Object?> get props => [message];
}
