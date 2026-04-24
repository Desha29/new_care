import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/models/inventory_model.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final IInventoryRepository _inventoryRepository;

  InventoryCubit({required IInventoryRepository inventoryRepository})
      : _inventoryRepository = inventoryRepository,
        super(InventoryInitial());

  Future<void> loadInventory() async {
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
      final currentState = state as InventoryLoaded;
      emit(InventoryLoaded(items: currentState.items, searchQuery: query));
    }
  }

  Future<void> addOrUpdateItem(InventoryModel item) async {
    try {
      await _inventoryRepository.updateInventoryItem(item);
      loadInventory();
    } catch (e) {
      emit(InventoryError('خطأ في التعديل: ${e.toString()}'));
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _inventoryRepository.deleteInventoryItem(id);
      loadInventory();
    } catch (e) {
      emit(InventoryError('خطأ في الحذف: ${e.toString()}'));
    }
  }
}
