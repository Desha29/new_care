import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notifications/case_change_notifier.dart';
import '../../../../core/services/notifications/data_change_notifier.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/models/inventory_model.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final IInventoryRepository _inventoryRepository;
  StreamSubscription? _caseChangeSubscription;

  StreamSubscription? _dataChangeSubscription;

  InventoryCubit({required IInventoryRepository inventoryRepository})
    : _inventoryRepository = inventoryRepository,
      super(InventoryInitial()) {
    _setupChangeListeners();
  }

  /// Listen to case changes and general data changes
  void _setupChangeListeners() {
    _caseChangeSubscription = CaseChangeNotifier().onCaseChanged.listen((event) {
      if (state is InventoryLoaded) {
        loadInventory(force: true);
      }
    });

    _dataChangeSubscription = DataChangeNotifier().onDataChanged.listen((_) {
      if (state is InventoryLoaded) {
        loadInventory(force: true);
      }
    });
  }

  @override
  Future<void> close() {
    _caseChangeSubscription?.cancel();
    _dataChangeSubscription?.cancel();
    return super.close();
  }

  Future<void> loadInventory({bool force = false}) async {
    if (!force && state is InventoryLoaded) return;

    emit(InventoryLoading());
    try {
      final items = await _inventoryRepository.getAllInventory();
      emit(InventoryLoaded(items: items));
    } catch (e) {
      emit(InventoryError('خطأ في تحميل المخزون: ${e.toString()}'));
    }
  }

  void searchInventory(String query) {
    if (state is InventoryLoaded) {
      final s = state as InventoryLoaded;
      emit(s.copyWith(searchQuery: query));
    }
  }

  void filterByCategory(String? category) {
    if (state is InventoryLoaded) {
      final s = state as InventoryLoaded;
      emit(s.copyWith(categoryFilter: category, clearCategoryFilter: category == null));
    }
  }

  void setStockFilter(String filter) {
    if (state is InventoryLoaded) {
      final s = state as InventoryLoaded;
      emit(s.copyWith(stockFilter: filter));
    }
  }

  void setExpiryFilter(String filter) {
    if (state is InventoryLoaded) {
      final s = state as InventoryLoaded;
      emit(s.copyWith(expiryFilter: filter));
    }
  }

  Future<void> addOrUpdateItem(InventoryModel item) async {
    try {
      await _inventoryRepository.updateInventoryItem(item);
      DataChangeNotifier().notifyLocalDataChanged();
      loadInventory(force: true);
    } catch (e) {
      emit(InventoryError('خطأ في التعديل: ${e.toString()}'));
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _inventoryRepository.deleteInventoryItem(id);
      DataChangeNotifier().notifyLocalDataChanged();
      loadInventory(force: true);
    } catch (e) {
      emit(InventoryError('خطأ في الحذف: ${e.toString()}'));
    }
  }
}
